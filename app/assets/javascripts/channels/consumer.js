//= require actioncable

const createConsumer = ActionCable.createConsumer;

window.App || (window.App = {});
App.cable = createConsumer();
console.log("App.cable initialized:", App.cable);

// import { createConsumer } from "@rails/actioncable";
//
// export default createConsumer();

