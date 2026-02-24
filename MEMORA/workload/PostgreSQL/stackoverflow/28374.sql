
WITH TagPostCounts AS (
    SELECT 
        UNNEST(string_to_array(substring(Tags, 2, length(Tags)-2), '><')) AS Tag,
        COUNT(*) AS PostCount
    FROM 
        Posts
    WHERE 
        PostTypeId = 1 
    GROUP BY 
        UNNEST(string_to_array(substring(Tags, 2, length(Tags)-2), '><'))
),
HighReputationUsers AS (
    SELECT 
        U.Id AS UserId, 
        U.DisplayName, 
        U.Reputation
    FROM 
        Users U
    WHERE 
        U.Reputation > (SELECT AVG(Reputation) FROM Users) 
),
PostEditHistory AS (
    SELECT 
        PH.PostId, 
        COUNT(*) AS EditCount,
        MAX(PH.CreationDate) AS LastEditDate
    FROM 
        PostHistory PH
    WHERE 
        PH.PostHistoryTypeId IN (4, 5, 6) 
    GROUP BY 
        PH.PostId
),
PopularTags AS (
    SELECT 
        Tag, 
        SUM(PostCount) AS TotalPosts
    FROM 
        TagPostCounts 
    GROUP BY 
        Tag 
    HAVING 
        SUM(PostCount) > 10 
),
PublicVotesCount AS (
    SELECT 
        P.Id AS PostId,
        COUNT(V.Id) AS VoteCount,
        SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVoteCount,
        SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVoteCount
    FROM 
        Posts P
    LEFT JOIN 
        Votes V ON P.Id = V.PostId
    GROUP BY 
        P.Id
)

SELECT 
    P.Title,
    T.Tag,
    U.DisplayName AS User,
    E.EditCount,
    E.LastEditDate,
    V.VoteCount,
    V.UpVoteCount,
    V.DownVoteCount
FROM 
    Posts P
JOIN 
    PublicVotesCount V ON P.Id = V.PostId
JOIN 
    PostEditHistory E ON P.Id = E.PostId
JOIN 
    HighReputationUsers U ON P.OwnerUserId = U.UserId
JOIN 
    PopularTags T ON T.Tag = ANY(string_to_array(substring(P.Tags, 2, length(P.Tags)-2), '><'))
WHERE 
    P.CreationDate >= CAST('2024-10-01 12:34:56' AS TIMESTAMP) - INTERVAL '1 year' 
ORDER BY 
    V.UpVoteCount DESC, E.LastEditDate DESC
LIMIT 50;
