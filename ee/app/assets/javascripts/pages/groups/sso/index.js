import UsernameValidator from '~/pages/sessions/new/username_validator';
import initConfirmDangerModal from '~/confirm_danger_modal';

document.addEventListener('DOMContentLoaded', () => {
  new UsernameValidator(); // eslint-disable-line no-new
  initConfirmDangerModal();
});
