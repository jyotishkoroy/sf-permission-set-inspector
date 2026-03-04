import { LightningElement, api, track } from 'lwc';
import searchUsers from '@salesforce/apex/PSI_AppController.searchUsers';

export default class PsiUserPicker extends LightningElement {
  @api label = 'User';
  @api selectedUserId = null;
  @api selectedUserLabel = '';
  @track results = [];
  @track busy = false;
  @track showList = false;

  _term = '';
  _timer = null;

  get valueLabel() {
    return this._term ? this._term : (this.selectedUserLabel || '');
  }

  onInput(e) {
    const term = e.target.value || '';
    this._term = term;
    this.selectedUserId = null;
    this.selectedUserLabel = '';
    this.dispatchEvent(new CustomEvent('userclear'));

    if (this._timer) clearTimeout(this._timer);
    this._timer = setTimeout(() => this.search(term), 250);
  }

  async search(term) {
    const q = String(term || '').trim();
    if (q.length < 2) {
      this.results = [];
      this.showList = false;
      return;
    }

    this.busy = true;
    this.showList = true;
    try {
      const res = await searchUsers({ queryText: q, limitSize: 15 });
      this.results = (res || []).map(u => ({
        ...u,
        activeLabel: u.isActive ? 'ACTIVE' : 'INACTIVE',
        activeClass: u.isActive ? 'pill pillOk' : 'pill pillWarn'
      }));
    } finally {
      this.busy = false;
    }
  }

  select(e) {
    const id = e.currentTarget.dataset.id;
    const u = (this.results || []).find(r => r.id === id);
    if (!u) return;

    this.selectedUserId = u.id;
    this.selectedUserLabel = `${u.name} (${u.username})`;
    this._term = '';
    this.showList = false;

    this.dispatchEvent(new CustomEvent('userselect', { detail: { user: u } }));
  }
}
