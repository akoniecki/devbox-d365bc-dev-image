# Microsoft Dev Box Environment Image for Business Central 📦 

Easily deploy a **fully configured Microsoft Dev Box** environment for Dynamics 365 Business Central development! This repository provides templates to automate the creation of a development image with all the tools you need, ready to use in minutes.  

## 🌟 One-Click Deployment  

Skip the hassle and deploy instantly with just one click:  

[![Deploy to Azure](https://aka.ms/deploytoazurebutton)](https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2Fakoniecki%2Fdevbox-d365bc-dev-image%2Fmain%2Fdevbox-d365bc-dev-image.json)  

## 🛠️ What’s Included  

- **Pre-installed Tools for Development**:  
  ✅ Docker Engine & Service  
  ✅ Visual Studio Code with Extensions:  
  - AL Language  
  - Docker Support  
  - GitHub Actions  
  ✅ GitHub CLI  
  ✅ BCContainerHelper Module  

- **Azure Image Builder Integration**:  
  🔹 Automatically creates a custom image.  
  🔹 Distributes the image via Azure Compute Gallery.  
  🔹 Ensures scalability with replication across selected regions.  

## 📋 How to Use  

1. **Click** the **Deploy to Azure** button above.  
2. Fill in the deployment form in the Azure Portal:  
   - Choose your **Azure Region** (e.g., `westeurope`, `eastus`).  
   - Customize resource names (optional).  
3. **Review and deploy**!  
4. After deployment, start the build in Image Template and your image will be available in the Azure Compute Gallery for use with Dev Boxes or even static VMs.  

## 📋 Expert corner

**Deploy with Bicep**  
   - Use the following command to deploy directly from the Bicep file:  
     ```bash
     az deployment sub create \
       --location <azure-location> \
       --template-file devbox-d365bc-dev-image.bicep
     ```  
     Replace `<azure-location>` with your desired Azure region (e.g., `westeurope`, `eastus`).  

**Generate JSON from Bicep**  
   - If you customised your bicep and still want to use json, convert the Bicep file to a JSON ARM template with:  
     ```bash
     az bicep build --file devbox-d365bc-dev-image.bicep
     ```  

**Deploy via JSON**  
   - Deploy the generated JSON template using:  
     ```bash
     az deployment sub create \
       --location <azure-location> \
       --template-file devbox-d365bc-dev-image.json
     ```  


## 🔑 Prerequisites  

- An active Azure subscription.  
- Contributor access to your subscription or resource group.  

## 📂 Repository Contents  

- **`devbox-d365bc-dev-image.bicep`**: Main Bicep template defining resources and configurations.  
- **`devbox-d365bc-dev-image.json`**: JSON template generated from the Bicep file for deployment.  

---

💡 **Pro Tip**: Contribute by reporting issues, suggesting improvements, or creating pull requests. Together, we make this project even better! Leave a Star, if you like the project. 

📄 **License**: [MIT](LICENSE)  
