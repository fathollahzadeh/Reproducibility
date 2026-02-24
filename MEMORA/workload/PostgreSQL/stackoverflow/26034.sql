
WITH TagCounts AS (
    SELECT 
        TagName,
        COUNT(*) AS PostCount
    FROM 
        Tags
    GROUP BY 
        TagName
    HAVING 
        COUNT(*) > 100
),
TopUsers AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
        COUNT(DISTINCT P.Id) AS PostsCreated
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN 
        Votes V ON P.Id = V.PostId
    GROUP BY 
        U.Id, U.DisplayName
    HAVING 
        COUNT(DISTINCT P.Id) > 5
    ORDER BY 
        UpVotes - DownVotes DESC
    LIMIT 10
),
PostStatistics AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        COALESCE(P.AcceptedAnswerId, 0) AS AcceptedAnswer,
        P.Score,
        P.CreationDate,
        U.DisplayName AS OwnerDisplayName,
        (SELECT COUNT(1) FROM Comments WHERE PostId = P.Id) AS CommentCount,
        (SELECT COUNT(1) FROM Badges WHERE UserId = P.OwnerUserId) AS BadgeCount
    FROM 
        Posts P
    INNER JOIN 
        Users U ON P.OwnerUserId = U.Id
    WHERE 
        P.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 year'
)
SELECT 
    T.TagName,
    COUNT(DISTINCT PS.PostId) AS PostCount,
    SUM(PS.CommentCount) AS TotalComments,
    SUM(PS.BadgeCount) AS TotalBadges,
    SUM(CASE WHEN PS.AcceptedAnswer > 0 THEN 1 ELSE 0 END) AS AcceptedAnswers,
    SUM(CASE WHEN PH.UserDisplayName IS NOT NULL THEN 1 ELSE 0 END) AS UserEditCount
FROM 
    TagCounts T
JOIN 
    Posts P ON P.Tags LIKE '%' || T.TagName || '%'
JOIN 
    PostStatistics PS ON P.Id = PS.PostId
LEFT JOIN 
    PostHistory PH ON PH.PostId = P.Id AND PH.UserId IN (SELECT UserId FROM TopUsers)
GROUP BY 
    T.TagName
ORDER BY 
    PostCount DESC;
