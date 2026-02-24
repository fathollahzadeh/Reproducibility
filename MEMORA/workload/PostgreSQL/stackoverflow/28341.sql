
WITH TagCounts AS (
    SELECT 
        unnest(string_to_array(substring(Tags, 2, length(Tags) - 2), '>><')) AS TagName,
        COUNT(*) AS PostCount
    FROM 
        Posts
    WHERE 
        PostTypeId = 1 
    GROUP BY 
        TagName
), 
UserReputation AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END) AS TotalUpvotes,
        SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END) AS TotalDownvotes,
        SUM(CASE WHEN V.VoteTypeId = 1 THEN 1 ELSE 0 END) AS AcceptedAnswers
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN 
        Votes V ON P.Id = V.PostId
    GROUP BY 
        U.Id, U.DisplayName
), 
PostStatistics AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.CreationDate,
        COUNT(CASE WHEN C.PostId IS NOT NULL THEN 1 END) AS CommentCount,
        COUNT(DISTINCT CASE WHEN V.Id IS NOT NULL THEN V.Id END) AS VoteCount,
        AVG(EXTRACT(EPOCH FROM (TIMESTAMP '2024-10-01 12:34:56' - P.CreationDate)) / 3600) AS AvgHoursSinceCreation
    FROM 
        Posts P
    LEFT JOIN 
        Comments C ON P.Id = C.PostId
    LEFT JOIN 
        Votes V ON P.Id = V.PostId
    GROUP BY 
        P.Id, P.Title, P.CreationDate
)
SELECT 
    TC.TagName,
    TC.PostCount,
    UR.UserId,
    UR.DisplayName,
    UR.TotalUpvotes,
    UR.TotalDownvotes,
    UR.AcceptedAnswers,
    PS.PostId,
    PS.Title,
    PS.CommentCount,
    PS.VoteCount,
    PS.AvgHoursSinceCreation
FROM 
    TagCounts TC
JOIN 
    Posts P ON P.Tags LIKE CONCAT('%', TC.TagName, '%')
JOIN 
    UserReputation UR ON P.OwnerUserId = UR.UserId
JOIN 
    PostStatistics PS ON P.Id = PS.PostId
WHERE 
    TC.PostCount > 10 
ORDER BY 
    TC.PostCount DESC, UR.TotalUpvotes DESC, PS.AvgHoursSinceCreation ASC;
