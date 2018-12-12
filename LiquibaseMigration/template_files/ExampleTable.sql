--liquibase formatted sql

--changeset peter.henell:JIRA-01234-add-Area-table
Create table CityArea(
	CityAreaID		bigint identity(1, 1) constraint [PK_CityArea] primary key,
	Description		varchar(500)
);


