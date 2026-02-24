WITH PostTagCounts AS (
    SELECT 
        P.Id AS PostId,
        COUNT(DISTINCT T.TagName) AS TagCount
    FROM 
        Posts P
    JOIN 
        UNNEST(string_to_array(SUBSTRING(P.Tags, 2, LENGTH(P.Tags)-2), '><')) AS T(TagName) ON TRUE
    GROUP BY 
        P.Id
),
UserEngagement AS (
    SELECT 
        U.Id AS UserId,
        SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        COUNT(CASE WHEN C.Id IS NOT NULL THEN 1 END) AS CommentCount,
        COUNT(DISTINCT PH.Id) AS EditCount,
        COUNT(DISTINCT PH.PostId) AS EditedPostCount
    FROM 
        Users U
    LEFT JOIN 
        Votes V ON U.Id = V.UserId
    LEFT JOIN 
        Comments C ON U.Id = C.UserId
    LEFT JOIN 
        PostHistory PH ON U.Id = PH.UserId
    GROUP BY 
        U.Id
),
PostWithMaxTags AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.ViewCount,
        TAG.TagCount
    FROM 
        Posts P
    JOIN 
        PostTagCounts TAG ON P.Id = TAG.PostId
    WHERE 
        TAG.TagCount = (SELECT MAX(TagCount) FROM PostTagCounts)
),
EngagedUsers AS (
    SELECT 
        U.DisplayName,
        U.Reputation,
        E.UpVotes,
        E.CommentCount,
        E.EditCount,
        E.EditedPostCount
    FROM 
        Users U
    JOIN 
        UserEngagement E ON U.Id = E.UserId
    WHERE 
        E.UpVotes > 50 AND E.CommentCount > 10
)
SELECT 
    PM.PostId,
    PM.Title,
    PM.ViewCount,
    EU.DisplayName,
    EU.Reputation,
    EU.UpVotes,
    EU.CommentCount
FROM 
    PostWithMaxTags PM
JOIN 
    EngagedUsers EU ON EU.UpVotes = (SELECT MAX(UpVotes) FROM UserEngagement);

