import { LightningElement, api } from 'lwc';

export default class PsiSnapshotPanel extends LightningElement {
  @api snapshot;

  get activeLabel() {
    return this.snapshot?.user?.isActive ? 'ACTIVE' : 'INACTIVE';
  }
  get activePill() {
    return this.snapshot?.user?.isActive ? 'pill pillOk' : 'pill pillWarn';
  }
}
