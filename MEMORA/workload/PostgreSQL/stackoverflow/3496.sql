WITH UserActivity AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        SUM(CASE WHEN P.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        SUM(CASE WHEN P.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount,
        COUNT(DISTINCT C.Id) AS CommentCount,
        COUNT(DISTINCT B.Id) AS BadgeCount,
        COALESCE(SUM(V.BountyAmount), 0) AS TotalBounty,
        MAX(P.CreationDate) AS LastPostDate
    FROM
        Users U
    LEFT JOIN
        Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN
        Comments C ON P.Id = C.PostId
    LEFT JOIN
        Badges B ON U.Id = B.UserId
    LEFT JOIN
        Votes V ON P.Id = V.PostId
    GROUP BY 
        U.Id, U.DisplayName
),
TopUsers AS (
    SELECT 
        UserId,
        DisplayName,
        QuestionCount,
        AnswerCount,
        CommentCount,
        BadgeCount,
        TotalBounty,
        LastPostDate,
        ROW_NUMBER() OVER (ORDER BY (QuestionCount * 2 + AnswerCount + CommentCount + BadgeCount + TotalBounty) DESC) AS Rank
    FROM 
        UserActivity
)
SELECT 
    TU.DisplayName,
    TU.QuestionCount,
    TU.AnswerCount,
    TU.CommentCount,
    TU.BadgeCount,
    TU.TotalBounty,
    TU.LastPostDate,
    CASE 
        WHEN TU.BadgeCount > 10 THEN 'Expert'
        WHEN TU.BadgeCount BETWEEN 5 AND 10 THEN 'Intermediate'
        ELSE 'Novice'
    END AS UserLevel
FROM 
    TopUsers TU
WHERE 
    TU.Rank <= 10
ORDER BY 
    TU.TotalBounty DESC;
