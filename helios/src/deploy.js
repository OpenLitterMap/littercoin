import * as helios from "./helios.js"


const lcValidatorSrc = await Deno.readTextFile("./src/lcValidator.cs");
const programLC = helios.Program.new(lcValidatorSrc);
const simplifyLC = false;
const lcUplcProgramLC = programLC.compile(simplifyLC);
const lcDatum = programLC.evalParam("LC_DATUM");
const lcDatumData = lcDatum.data;
const lcAddAdaRedeemer = programLC.evalParam("LC_ADD_ADA_REDEEMER");
const lcAddAdaRedeemerData = lcAddAdaRedeemer.data;
const lcMintRedeemer = programLC.evalParam("LC_MINT_REDEEMER");
const lcMintRedeemerData = lcMintRedeemer.data;

//const mphData = helios.UplcData.fromCbor(mph.toCbor());
//programLC.changeParam("TT_MPH", helios.UplcByteArray.new(mphData));
//programLC.changeParam("TT_MPH", mphData);
//programLC.changeParam("TT_MPH", JSON.stringify(["#123"]));
//programLC.changeParam("TT_MPH", JSON.stringify([mph.hex]));
//programLC.evalParam("TT_MPH");

await Deno.writeTextFile("./deploy/redeemer-add-ada.json", lcAddAdaRedeemerData.toSchemaJson());
await Deno.writeTextFile("./deploy/redeemer-mint.json", lcMintRedeemerData.toSchemaJson());
await Deno.writeTextFile("./deploy/lc-datum-init.json", lcDatumData.toSchemaJson());
await Deno.writeTextFile("./deploy/lc-validator.plutus", lcUplcProgramLC.serialize());

