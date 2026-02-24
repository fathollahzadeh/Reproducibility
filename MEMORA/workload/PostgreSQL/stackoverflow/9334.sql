
WITH UserPostCounts AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COUNT(P.Id) AS PostCount,
        SUM(CASE WHEN P.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        SUM(CASE WHEN P.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount,
        SUM(CASE WHEN P.PostTypeId = 3 THEN 1 ELSE 0 END) AS WikiCount
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    GROUP BY 
        U.Id, U.DisplayName
),
TopUsers AS (
    SELECT 
        UserId,
        DisplayName,
        PostCount,
        QuestionCount,
        AnswerCount,
        WikiCount,
        ROW_NUMBER() OVER (ORDER BY PostCount DESC) AS Rank
    FROM 
        UserPostCounts
)
SELECT 
    T.DisplayName,
    T.PostCount,
    T.QuestionCount,
    T.AnswerCount,
    T.WikiCount,
    COALESCE(S.SumUpVotes, 0) AS TotalUpVotes,
    COALESCE(S.SumDownVotes, 0) AS TotalDownVotes,
    COALESCE(B.BadgeCount, 0) AS TotalBadges,
    COUNT(DISTINCT C.Id) AS TotalComments
FROM 
    TopUsers T
LEFT JOIN 
    (SELECT 
        UserId,
        SUM(UpVotes) AS SumUpVotes,
        SUM(DownVotes) AS SumDownVotes
    FROM 
        Users
    GROUP BY 
        UserId) S ON T.UserId = S.UserId
LEFT JOIN 
    (SELECT 
        UserId,
        COUNT(Id) AS BadgeCount
    FROM 
        Badges
    GROUP BY 
        UserId) B ON T.UserId = B.UserId
LEFT JOIN 
    Comments C ON T.UserId = C.UserId
WHERE 
    T.Rank <= 10
GROUP BY 
    T.DisplayName, T.PostCount, T.QuestionCount, T.AnswerCount, T.WikiCount, S.SumUpVotes, S.SumDownVotes, B.BadgeCount, T.Rank
ORDER BY 
    T.Rank;
