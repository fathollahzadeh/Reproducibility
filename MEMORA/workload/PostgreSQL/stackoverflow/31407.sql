
WITH RECURSIVE PostActivity AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.OwnerUserId,
        COALESCE(p.AcceptedAnswerId, 0) AS AcceptedAnswerId,
        COALESCE(v.UpVoteCount, 0) AS UpVoteCount,
        COALESCE(v.DownVoteCount, 0) AS DownVoteCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS rn
    FROM 
        Posts p
    LEFT JOIN (
        SELECT 
            PostId, 
            COUNT(CASE WHEN VoteTypeId = 2 THEN 1 END) AS UpVoteCount,
            COUNT(CASE WHEN VoteTypeId = 3 THEN 1 END) AS DownVoteCount
        FROM 
            Votes
        GROUP BY 
            PostId
    ) v ON p.Id = v.PostId
    WHERE 
        p.CreationDate >= CURRENT_DATE - INTERVAL '1 year'
    UNION ALL
    SELECT 
        p.Id,
        p.Title,
        p.CreationDate,
        p.OwnerUserId,
        COALESCE(p.AcceptedAnswerId, 0),
        COALESCE(v.UpVoteCount, 0),
        COALESCE(v.DownVoteCount, 0),
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC)
    FROM 
        Posts p
    INNER JOIN PostActivity pa ON p.Id = pa.AcceptedAnswerId
    LEFT JOIN (
        SELECT 
            PostId, 
            COUNT(CASE WHEN VoteTypeId = 2 THEN 1 END) AS UpVoteCount,
            COUNT(CASE WHEN VoteTypeId = 3 THEN 1 END) AS DownVoteCount
        FROM 
            Votes
        GROUP BY 
            PostId
    ) v ON p.Id = v.PostId
)
SELECT 
    u.DisplayName,
    COUNT(DISTINCT pa.PostId) AS TotalPosts,
    SUM(pa.UpVoteCount) AS TotalUpVotes,
    SUM(pa.DownVoteCount) AS TotalDownVotes,
    AVG(EXTRACT(EPOCH FROM (CURRENT_TIMESTAMP - pa.CreationDate))) AS AvgPostAge
FROM 
    Users u
LEFT JOIN PostActivity pa ON u.Id = pa.OwnerUserId
WHERE 
    u.Reputation >= 1000
GROUP BY 
    u.DisplayName
ORDER BY 
    TotalPosts DESC, TotalUpVotes DESC
LIMIT 10 OFFSET 0;
