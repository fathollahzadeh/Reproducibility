
WITH UserStats AS (
    SELECT 
        U.Id AS UserId,
        U.Reputation,
        U.CreationDate,
        COUNT(DISTINCT P.Id) AS PostCount,
        SUM(CASE WHEN P.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        SUM(CASE WHEN P.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount,
        SUM(CASE WHEN P.ViewCount IS NOT NULL THEN P.ViewCount ELSE 0 END) AS TotalViews,
        SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN 
        Votes V ON P.Id = V.PostId
    GROUP BY 
        U.Id, U.Reputation, U.CreationDate
),
TopUsers AS (
    SELECT 
        UserId,
        Reputation,
        CreationDate,
        PostCount,
        QuestionCount,
        AnswerCount,
        TotalViews,
        UpVotes,
        DownVotes,
        RANK() OVER (ORDER BY Reputation DESC) AS RankByReputation,
        RANK() OVER (ORDER BY TotalViews DESC) AS RankByViews
    FROM 
        UserStats
)
SELECT 
    UserId,
    Reputation,
    CreationDate,
    PostCount,
    QuestionCount,
    AnswerCount,
    TotalViews,
    UpVotes,
    DownVotes,
    RankByReputation,
    RankByViews
FROM 
    TopUsers
WHERE 
    RankByReputation <= 10 OR RankByViews <= 10
ORDER BY 
    RankByReputation, RankByViews;
