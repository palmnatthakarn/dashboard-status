import 'package:json_annotation/json_annotation.dart';

part 'journal_detail.g.dart';

@JsonSerializable()
class JournalDetail {
  final String? guidfixed;
  final String? batchid;
  final String? docno;
  final String? docdate;
  final String? documentref;
  final int? accountperiod;
  final int? accountyear;
  final String? accountgroup;
  final double? amount;
  final String? accountdescription;
  final String? bookcode;
  final List<dynamic>? vats;
  final List<dynamic>? taxes;
  final int? journaltype;
  final String? exdocrefno;
  final String? exdocrefdate;
  final String? docformat;
  final String? appname;
  final int? debtaccounttype;
  final JournalPerson? creditor;
  final JournalPerson? debtor;
  final String? jobguidfixed;
  final List<JournalDetailItem>? journaldetail;
  final String? createdby;
  final String? createdat;

  JournalDetail({
    this.guidfixed,
    this.batchid,
    this.docno,
    this.docdate,
    this.documentref,
    this.accountperiod,
    this.accountyear,
    this.accountgroup,
    this.amount,
    this.accountdescription,
    this.bookcode,
    this.vats,
    this.taxes,
    this.journaltype,
    this.exdocrefno,
    this.exdocrefdate,
    this.docformat,
    this.appname,
    this.debtaccounttype,
    this.creditor,
    this.debtor,
    this.jobguidfixed,
    this.journaldetail,
    this.createdby,
    this.createdat,
  });

  factory JournalDetail.fromJson(Map<String, dynamic> json) =>
      _$JournalDetailFromJson(json);
  Map<String, dynamic> toJson() => _$JournalDetailToJson(this);
}

@JsonSerializable()
class JournalPerson {
  final String? guidfixed;
  final String? code;
  final int? personaltype;
  final int? customertype;
  final String? branchnumber;
  final String? taxid;
  final List<PersonName>? names;

  JournalPerson({
    this.guidfixed,
    this.code,
    this.personaltype,
    this.customertype,
    this.branchnumber,
    this.taxid,
    this.names,
  });

  factory JournalPerson.fromJson(Map<String, dynamic> json) =>
      _$JournalPersonFromJson(json);
  Map<String, dynamic> toJson() => _$JournalPersonToJson(this);
}

@JsonSerializable()
class PersonName {
  final String? code;
  final String? name;
  final bool? isauto;
  final bool? isdelete;

  PersonName({this.code, this.name, this.isauto, this.isdelete});

  factory PersonName.fromJson(Map<String, dynamic> json) =>
      _$PersonNameFromJson(json);
  Map<String, dynamic> toJson() => _$PersonNameToJson(this);
}

@JsonSerializable()
class JournalDetailItem {
  final String? accountcode;
  final String? accountname;
  final double? debitamount;
  final double? creditamount;

  JournalDetailItem({
    this.accountcode,
    this.accountname,
    this.debitamount,
    this.creditamount,
  });

  factory JournalDetailItem.fromJson(Map<String, dynamic> json) =>
      _$JournalDetailItemFromJson(json);
  Map<String, dynamic> toJson() => _$JournalDetailItemToJson(this);
}
