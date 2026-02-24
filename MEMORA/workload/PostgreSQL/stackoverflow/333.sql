
WITH UserStats AS (
    SELECT 
        U.Id AS UserId, 
        U.DisplayName, 
        U.Reputation, 
        U.CreationDate,
        COUNT(DISTINCT P.Id) AS TotalPosts,
        SUM(CASE WHEN P.Score > 0 THEN 1 ELSE 0 END) AS PositivePosts,
        SUM(CASE WHEN P.Score < 0 THEN 1 ELSE 0 END) AS NegativePosts,
        AVG(P.Score) AS AverageScore
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    GROUP BY 
        U.Id, U.DisplayName, U.Reputation, U.CreationDate
),
TopTags AS (
    SELECT 
        T.TagName,
        COUNT(P.Id) AS PostCount
    FROM 
        Tags T
    JOIN 
        Posts P ON P.Tags LIKE CONCAT('%', T.TagName, '%')
    GROUP BY 
        T.TagName
    ORDER BY 
        PostCount DESC
    LIMIT 10
),
RecentVotes AS (
    SELECT 
        V.UserId,
        COUNT(V.Id) AS VoteCount,
        SUM(CASE WHEN VT.Name = 'UpMod' THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN VT.Name = 'DownMod' THEN 1 ELSE 0 END) AS DownVotes
    FROM 
        Votes V
    JOIN 
        VoteTypes VT ON V.VoteTypeId = VT.Id
    WHERE 
        V.CreationDate >= CAST('2024-10-01 12:34:56' AS TIMESTAMP) - INTERVAL '30 DAYS'
    GROUP BY 
        V.UserId
)
SELECT 
    U.DisplayName AS UserDisplayName,
    U.Reputation AS UserReputation,
    COALESCE(US.TotalPosts, 0) AS UserTotalPosts,
    COALESCE(US.PositivePosts, 0) AS UserPositivePosts,
    COALESCE(US.NegativePosts, 0) AS UserNegativePosts,
    COALESCE(US.AverageScore, 0) AS UserAverageScore,
    TT.TagName AS PopularTag,
    TT.PostCount AS TagPostCount,
    RV.VoteCount AS RecentVoteCount,
    RV.UpVotes AS RecentUpVotes,
    RV.DownVotes AS RecentDownVotes
FROM 
    Users U
LEFT JOIN 
    UserStats US ON U.Id = US.UserId
LEFT JOIN 
    TopTags TT ON TRUE
LEFT JOIN 
    RecentVotes RV ON U.Id = RV.UserId
WHERE 
    U.Reputation > 1000
ORDER BY 
    U.Reputation DESC, 
    TagPostCount DESC
LIMIT 50;
