
WITH TagFrequency AS (
    SELECT 
        UNNEST(string_to_array(SUBSTR(Tags, 2, LENGTH(Tags) - 2), '><')) AS Tag,
        COUNT(*) AS TagCount
    FROM 
        Posts
    WHERE 
        PostTypeId = 1
    GROUP BY 
        Tag
),
TopTags AS (
    SELECT 
        Tag, 
        TagCount
    FROM 
        TagFrequency
    ORDER BY 
        TagCount DESC
    LIMIT 10
),
UserActivity AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COUNT(DISTINCT P.Id) AS PostsCount,
        COUNT(DISTINCT C.Id) AS CommentsCount,
        SUM(COALESCE(V.BountyAmount, 0)) AS TotalBounty,
        SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN 
        Comments C ON P.Id = C.PostId
    LEFT JOIN 
        Votes V ON V.UserId = U.Id
    GROUP BY 
        U.Id, U.DisplayName
)

SELECT 
    A.UserId,
    A.DisplayName,
    A.PostsCount,
    A.CommentsCount,
    A.TotalBounty,
    A.UpVotes,
    A.DownVotes,
    T.Tag,
    T.TagCount
FROM 
    UserActivity A
CROSS JOIN 
    TopTags T
WHERE 
    A.PostsCount > 5
ORDER BY 
    A.PostsCount DESC, 
    T.TagCount DESC;
