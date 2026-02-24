
WITH UserVoteStats AS (
    SELECT 
        u.Id AS UserId,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS UpVotes,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS DownVotes,
        COUNT(DISTINCT p.Id) AS TotalPosts,
        COUNT(DISTINCT CASE WHEN p.Score > 0 THEN p.Id END) AS PositivePosts,
        COUNT(DISTINCT CASE WHEN p.Score <= 0 THEN p.Id END) AS NegativePosts
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    GROUP BY 
        u.Id
),
PostClosureCount AS (
    SELECT 
        ph.UserId,
        COUNT(*) AS TotalClosures
    FROM 
        PostHistory ph
    WHERE 
        ph.PostHistoryTypeId IN (10, 11) 
    GROUP BY 
        ph.UserId
),
PostMetrics AS (
    SELECT 
        p.Id,
        p.Title,
        p.Score,
        p.CreationDate,
        COUNT(c.Id) AS CommentCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVoteCount,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVoteCount
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    GROUP BY 
        p.Id, p.Title, p.Score, p.CreationDate
),
RankedPosts AS (
    SELECT 
        pm.Id,
        pm.Title,
        pm.Score,
        pm.CommentCount,
        pm.UpVoteCount,
        pm.DownVoteCount,
        RANK() OVER (ORDER BY pm.Score DESC, pm.CommentCount DESC) AS PostRank
    FROM 
        PostMetrics pm
)
SELECT 
    u.DisplayName,
    u.Reputation,
    COALESCE(uv.UpVotes, 0) AS TotalUpVotes,
    COALESCE(uv.DownVotes, 0) AS TotalDownVotes,
    COALESCE(pc.TotalClosures, 0) AS TotalClosures,
    rp.Title,
    rp.CommentCount,
    rp.UpVoteCount,
    rp.DownVoteCount,
    rp.PostRank
FROM 
    Users u
LEFT JOIN 
    UserVoteStats uv ON u.Id = uv.UserId
LEFT JOIN 
    PostClosureCount pc ON u.Id = pc.UserId
JOIN 
    RankedPosts rp ON u.Id = rp.Id
WHERE 
    (COALESCE(uv.UpVotes, 0) + COALESCE(uv.DownVotes, 0)) > (SELECT AVG(COALESCE(uv2.UpVotes, 0) + COALESCE(uv2.DownVotes, 0)) FROM UserVoteStats uv2)
    AND rp.PostRank <= 10
ORDER BY 
    rp.PostRank;
