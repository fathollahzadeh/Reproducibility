
WITH UserStats AS (
    SELECT 
        u.Id AS UserId, 
        u.DisplayName, 
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS UpVotesCount,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS DownVotesCount,
        COUNT(DISTINCT p.Id) AS PostsCount
    FROM Users u
    LEFT JOIN Votes v ON u.Id = v.UserId
    LEFT JOIN Posts p ON u.Id = p.OwnerUserId
    GROUP BY u.Id, u.DisplayName
), FrequentPosters AS (
    SELECT 
        UserId, 
        DisplayName, 
        PostsCount,
        ROW_NUMBER() OVER (ORDER BY PostsCount DESC) AS PostRank 
    FROM UserStats
    WHERE PostsCount > 5
), PopularPostTags AS (
    SELECT 
        tags.TagName, 
        COUNT(p.Id) AS TagPostCount
    FROM Posts p
    JOIN Tags tags ON p.Tags LIKE CONCAT('%', tags.TagName, '%')
    GROUP BY tags.TagName
    HAVING COUNT(p.Id) > 10
), RecentVotes AS (
    SELECT 
        v.UserId, 
        COUNT(v.Id) AS RecentVoteCount
    FROM Votes v
    WHERE v.CreationDate >= CURRENT_TIMESTAMP - INTERVAL '30 days'
    GROUP BY v.UserId
)
SELECT 
    fp.DisplayName,
    fp.PostsCount,
    COALESCE(rv.RecentVoteCount, 0) AS RecentVotes,
    (us.UpVotesCount - us.DownVotesCount) AS NetVotes,
    pt.TagPostCount
FROM FrequentPosters fp
LEFT JOIN UserStats us ON fp.UserId = us.UserId
LEFT JOIN RecentVotes rv ON fp.UserId = rv.UserId
LEFT JOIN PopularPostTags pt ON pt.TagPostCount = (
    SELECT MAX(TagPostCount) FROM PopularPostTags
)
ORDER BY fp.PostRank;
