const nyKnapp = document.getElementById("skapa-punkt");
const punktList = document.getElementById("punkter");
const form = document.getElementById("todo-form");
const titel = document.getElementById("titel");

const todo = {
  titel: "",
  punkter: [],
};

const raderaPunkt = (index) => () => {
  todo.punkter = todo.punkter.filter((p, i) => i !== index);
  uppdateraPunktLista(todo);
};

const uppdateraPunkt = (index) => (ev) => {
  ev.preventDefault();
  todo.punkter[index].etikett = ev.target.value;
  console.log(ev.target.value);
};

const uppdateraPunktLista = (todo) => {
  // återställ
  punktList.innerHTML = "";
  // lägg till varje punkt
  todo.punkter.forEach((punkt, index) => {
    const raderaKnapp = document.createElement("i");
    raderaKnapp.classList = "material-icons icon-button";
    raderaKnapp.innerText = "delete";
    raderaKnapp.onclick = raderaPunkt(index);

    const input = document.createElement("input");
    input.value = punkt.etikett;
    input.onchange = uppdateraPunkt(index);

    const div = document.createElement("div");
    div.className = "point-row";
    div.appendChild(raderaKnapp);
    div.appendChild(input);
    punktList.appendChild(div);
  });
};

nyKnapp.onclick = () => {
  console.log("test");
  todo.punkter.push({ etikett: "", klar: false });
  console.log(todo);
  uppdateraPunktLista(todo);
};

form.onsubmit = (e) => {
  e.preventDefault();

  fetch("/todo", {
    method: "POST",
    body: JSON.stringify({ punkter: todo.punkter, titel: titel.value }),
  }).then(() => {
    window.location = "/";
  });
};
