
WITH RankedUserVotes AS (
    SELECT 
        v.UserId,
        COUNT(CASE WHEN v.VoteTypeId = 2 THEN 1 END) AS UpVotes,
        COUNT(CASE WHEN v.VoteTypeId = 3 THEN 1 END) AS DownVotes,
        COUNT(CASE WHEN v.VoteTypeId = 10 THEN 1 END) AS Deletions,
        RANK() OVER (ORDER BY COUNT(v.Id) DESC) AS VoteRank
    FROM Votes v
    JOIN Posts p ON v.PostId = p.Id
    WHERE p.CreationDate >= CURRENT_DATE - INTERVAL '1 year'
    GROUP BY v.UserId
),
ActiveUsers AS (
    SELECT 
        u.Id,
        u.DisplayName,
        u.Reputation,
        u.LastAccessDate,
        COUNT(DISTINCT p.Id) AS ActivePosts
    FROM Users u
    JOIN Posts p ON u.Id = p.OwnerUserId
    WHERE u.LastAccessDate >= CURRENT_DATE - INTERVAL '6 months'
    GROUP BY u.Id, u.DisplayName, u.Reputation, u.LastAccessDate
)
SELECT 
    au.DisplayName,
    au.Reputation,
    au.ActivePosts,
    COALESCE(rv.UpVotes, 0) AS UpVotes,
    COALESCE(rv.DownVotes, 0) AS DownVotes,
    COALESCE(rv.Deletions, 0) AS Deletions,
    COALESCE(rv.VoteRank, 0) AS VoteRank
FROM ActiveUsers au
LEFT JOIN RankedUserVotes rv ON au.Id = rv.UserId
WHERE au.Reputation > 1000
ORDER BY rv.VoteRank, au.DisplayName;
