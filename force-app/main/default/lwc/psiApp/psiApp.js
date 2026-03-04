import { LightningElement, track } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

import getInfo from '@salesforce/apex/PSI_AppController.getInfo';
import getUserSnapshot from '@salesforce/apex/PSI_AppController.getUserSnapshot';
import compareUsers from '@salesforce/apex/PSI_AppController.compareUsers';

import { groupCounts } from 'c/psiUtil';

export default class PsiApp extends LightningElement {
  @track info = { version: '0.0.0', sandbox: false };
  busy = false;
  busyLabel = '';

  userA = null;
  userB = null;

  expandGroups = false;

  @track snapA = null;
  @track snapB = null;

  @track comparison = null;
  compareWarning = '';

  diffTab = 'ps';

  connectedCallback() {
    this.init();
  }

  async init() {
    await this.withBusy('Loading...', async () => {
      this.info = await getInfo();
    });
  }

  get envLabel() { return this.info.sandbox ? 'SANDBOX' : 'PRODUCTION'; }
  get envPillClass() { return this.info.sandbox ? 'pill pillOk' : 'pill pillHigh'; }

  get compareDisabled() { return this.busy || !this.userA?.id || !this.userB?.id; }
  get loadADisabled() { return this.busy || !this.userA?.id; }
  get loadBDisabled() { return this.busy || !this.userB?.id; }

  get isPermSetDiff() { return this.diffTab === 'ps'; }
  get isGroupDiff() { return this.diffTab === 'grp'; }
  get diffTabPsClass() { return this.isPermSetDiff ? 'tab tabActive' : 'tab'; }
  get diffTabGrpClass() { return this.isGroupDiff ? 'tab tabActive' : 'tab'; }

  get psCounts() { return groupCounts(this.comparison?.permissionSets); }
  get grpCounts() { return groupCounts(this.comparison?.groups); }

  showPermSetDiff = () => { this.diffTab = 'ps'; };
  showGroupDiff = () => { this.diffTab = 'grp'; };

  onPickA(e) { this.userA = e.detail.user; this.snapA = null; this.comparison = null; this.compareWarning=''; }
  onPickB(e) { this.userB = e.detail.user; this.snapB = null; this.comparison = null; this.compareWarning=''; }
  onClearA() { this.userA = null; this.snapA = null; this.comparison = null; this.compareWarning=''; }
  onClearB() { this.userB = null; this.snapB = null; this.comparison = null; this.compareWarning=''; }

  toggleExpand(e) { this.expandGroups = e.target.checked; }

  async loadA() {
    await this.withBusy('Loading user A...', async () => {
      this.snapA = await getUserSnapshot({ userId: this.userA.id, includeGroupExpansion: this.expandGroups });
      if (this.snapA?.warning) this.toast('Notice', this.snapA.warning, 'warning');
    });
  }

  async loadB() {
    await this.withBusy('Loading user B...', async () => {
      this.snapB = await getUserSnapshot({ userId: this.userB.id, includeGroupExpansion: this.expandGroups });
      if (this.snapB?.warning) this.toast('Notice', this.snapB.warning, 'warning');
    });
  }

  async compare() {
    await this.withBusy('Comparing...', async () => {
      const res = await compareUsers({ userAId: this.userA.id, userBId: this.userB.id, includeGroupExpansion: this.expandGroups });
      this.comparison = res;
      this.compareWarning = res?.warning || '';
      this.diffTab = 'ps';
      if (this.compareWarning) this.toast('Notice', this.compareWarning, 'warning');
    });
  }

  async refresh() {
    await this.withBusy('Refreshing...', async () => {
      this.info = await getInfo();
    });
  }

  async withBusy(label, fn) {
    this.busy = true;
    this.busyLabel = label || 'Working...';
    try { return await fn(); }
    catch (e) { this.toast('Error', this.humanError(e), 'error'); throw e; }
    finally { this.busy = false; this.busyLabel = ''; }
  }

  toast(title, message, variant) {
    this.dispatchEvent(new ShowToastEvent({ title, message, variant }));
  }

  humanError(e) {
    try {
      if (e?.body?.message) return e.body.message;
      if (Array.isArray(e?.body) && e.body[0]?.message) return e.body[0].message;
      if (e?.message) return e.message;
      return JSON.stringify(e);
    } catch { return String(e); }
  }
}
