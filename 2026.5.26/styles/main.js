// Select version from URL
const selectVersion = document.getElementById('select-version');
const indexOfFirstSlash = window.location.pathname.indexOf('/', 1);
const indexOfSecondSlash = window.location.pathname.indexOf('/', indexOfFirstSlash + 1);
const firstSegment = window.location.pathname.substring(1, indexOfFirstSlash);
const secondSegment = window.location.pathname.substring(indexOfFirstSlash + 1, indexOfSecondSlash);
var useFirstSegment = firstSegment.toLowerCase() !== 'everginedocs'? true : false;

// Load versions
const versionsUrl = useFirstSegment ? '/versions.json' : '/EvergineDocs/versions.json';
fetch(versionsUrl)
  .then(response => response.json())
  .then(json => {
      json.versions.forEach(version => {
        let option = document.createElement('option');
        option.value = version;
        option.innerText = version;
        option.className = "option-version";
        selectVersion.appendChild(option);
      });
    
      selectVersion.value = useFirstSegment? firstSegment : secondSegment;
    });

// Subscribe to version change
selectVersion.onchange = function() {
    const hostVersion = window.location.host;
    const pathVersion = window.location.pathname;
    let targetVersion = selectVersion.value;
    const segment = useFirstSegment? targetVersion : 'EvergineDocs' + '/' + targetVersion;
    const indexOfFirstSlash = pathVersion.indexOf('/', 1);
    const indexOfSecondSlash = pathVersion.indexOf('/', indexOfFirstSlash + 1);
    const slashToSkip = useFirstSegment? indexOfFirstSlash : indexOfSecondSlash;

    // Generate page URL in other version
    var newAddress = '//' + hostVersion + '/' + segment + '/' +  pathVersion.substring(slashToSkip + 1);

    // Check if address exists
    function handleErrors(response) {
        if (!response.ok) {
            throw Error(response.statusText);
        }
        return response;
    }

    fetch(newAddress)
        .then(handleErrors)
        .then(response => window.location.href = newAddress )
        .catch(error => window.location.href = '//' + hostVersion + '/' + segment);
};

