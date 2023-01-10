import { LightningElement, track } from 'lwc';

export default class Kiwi_onLeaveForm extends LightningElement {
  @track form = {
    email: '',
    emailAccepted: false
  }

  handleChangeInput(e) {
    const { name, value } = e.currentTarget;
    this.form[name] = value;
  }

  handleChangeCheckbox(e) {
    const { name, checked } = e.currentTarget;
    this.form[name] = checked;
  }

  handleSubmit(event) {
    event.preventDefault();
    console.log('submitting', JSON.stringify(this.form));
    this.dispatchEvent(new CustomEvent('save', {
      detail: this.form
    }));
  }

  handleClose() {
    this.dispatchEvent(new CustomEvent('close', {}));
  }
}