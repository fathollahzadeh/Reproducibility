
WITH UserTags AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        T.TagName,
        COUNT(P.Id) AS PostCount
    FROM 
        Users U
    JOIN 
        Posts P ON U.Id = P.OwnerUserId
    JOIN 
        (SELECT 
            P.Id, 
            unnest(string_to_array(substring(P.Tags, 2, length(P.Tags) - 2), '><')) AS TagName
         FROM 
            Posts P 
         WHERE 
            P.PostTypeId = 1) AS T ON P.Id = T.Id
    GROUP BY 
        U.Id, U.DisplayName, T.TagName
),
TopTags AS (
    SELECT 
        TagName,
        SUM(PostCount) AS TotalPosts
    FROM 
        UserTags
    GROUP BY 
        TagName
    ORDER BY 
        TotalPosts DESC
    LIMIT 10
),
PostStatistics AS (
    SELECT 
        P.Id AS PostId, 
        P.Title, 
        P.CreationDate, 
        P.ViewCount, 
        P.Score, 
        T.TagName,
        U.DisplayName AS OwnerName,
        (SELECT COUNT(*) FROM Comments C WHERE C.PostId = P.Id) AS CommentCount
    FROM 
        Posts P
    LEFT JOIN 
        UserTags U ON P.OwnerUserId = U.UserId
    JOIN 
        (SELECT 
            UserId, 
            TagName
         FROM 
            UserTags 
         WHERE 
            TagName IN (SELECT TagName FROM TopTags)) T ON P.OwnerUserId = T.UserId
    WHERE 
        P.PostTypeId = 1
)
SELECT 
    PS.Title,
    PS.CreationDate,
    PS.ViewCount,
    PS.Score,
    PS.CommentCount,
    PS.TagName,
    COUNT(V.Id) AS VoteCount,
    AVG(U.Reputation) AS AvgReputation
FROM 
    PostStatistics PS
LEFT JOIN 
    Votes V ON PS.PostId = V.PostId 
LEFT JOIN 
    Users U ON PS.OwnerName = U.DisplayName
GROUP BY 
    PS.Title, PS.CreationDate, PS.ViewCount, PS.Score, PS.CommentCount, PS.TagName
ORDER BY 
    VoteCount DESC, PS.Score DESC;
