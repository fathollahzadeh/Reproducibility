
WITH RECURSIVE UserActivity AS (
    SELECT 
        U.Id AS UserId, 
        U.DisplayName, 
        COUNT(DISTINCT P.Id) AS PostCount, 
        SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVoteCount,
        SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVoteCount
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN 
        Votes V ON P.Id = V.PostId
    WHERE 
        U.Reputation > 1000
    GROUP BY 
        U.Id, U.DisplayName
),
PopularTags AS (
    SELECT 
        T.TagName, 
        COUNT(P.Id) AS TagPostCount
    FROM 
        Tags T
    JOIN 
        Posts P ON P.Tags LIKE '%' || T.TagName || '%'
    WHERE 
        P.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 year'
    GROUP BY 
        T.TagName
),
TopTags AS (
    SELECT 
        TagName, 
        TagPostCount,
        RANK() OVER (ORDER BY TagPostCount DESC) AS TagRank
    FROM 
        PopularTags
)
SELECT 
    U.UserId,
    U.DisplayName,
    U.PostCount,
    U.UpVoteCount,
    U.DownVoteCount,
    COALESCE(TT.TagName, 'No Tags') AS PopularTag,
    TT.TagPostCount
FROM 
    UserActivity U
LEFT JOIN 
    TopTags TT ON U.PostCount > 0 AND TT.TagRank = 1
WHERE 
    U.PostCount > 0
ORDER BY 
    U.UpVoteCount DESC, 
    U.DisplayName;
