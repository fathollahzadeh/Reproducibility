WITH UserStats AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        COUNT(DISTINCT B.Id) AS BadgeCount,
        SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
        SUM(CASE WHEN P.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        SUM(CASE WHEN P.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount
    FROM 
        Users U
    LEFT JOIN 
        Badges B ON U.Id = B.UserId
    LEFT JOIN 
        Votes V ON U.Id = V.UserId
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    GROUP BY 
        U.Id, U.DisplayName, U.Reputation
),
TopUsers AS (
    SELECT 
        UserId,
        DisplayName,
        Reputation,
        BadgeCount,
        UpVotes,
        DownVotes,
        QuestionCount,
        AnswerCount,
        RANK() OVER (ORDER BY Reputation DESC, BadgeCount DESC) AS Rank
    FROM 
        UserStats
)
SELECT 
    UserId,
    DisplayName,
    Reputation,
    BadgeCount,
    UpVotes,
    DownVotes,
    QuestionCount,
    AnswerCount,
    Rank
FROM 
    TopUsers
WHERE 
    Rank <= 10
ORDER BY 
    Rank;
