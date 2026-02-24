
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.CreationDate DESC) AS Rank
    FROM 
        Posts p 
    WHERE 
        p.CreationDate >= CAST('2024-10-01 12:34:56' AS TIMESTAMP) - INTERVAL '1 year'
),
PostsWithVotes AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.CreationDate,
        rp.ViewCount,
        rp.Score,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS UpVotes,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS DownVotes,
        COUNT(DISTINCT CASE WHEN v.UserId IS NOT NULL THEN v.UserId END) AS UniqueVoterCount
    FROM 
        RankedPosts rp
    LEFT JOIN 
        Votes v ON rp.PostId = v.PostId
    GROUP BY 
        rp.PostId, rp.Title, rp.CreationDate, rp.ViewCount, rp.Score
),
PostsWithComments AS (
    SELECT 
        pwv.PostId,
        pwv.Title,
        pwv.CreationDate,
        pwv.ViewCount,
        pwv.Score,
        pwv.UpVotes,
        pwv.DownVotes,
        pwv.UniqueVoterCount,
        COALESCE(COUNT(c.Id), 0) AS CommentCount
    FROM 
        PostsWithVotes pwv
    LEFT JOIN 
        Comments c ON pwv.PostId = c.PostId
    GROUP BY 
        pwv.PostId, pwv.Title, pwv.CreationDate, pwv.ViewCount, pwv.Score, pwv.UpVotes, pwv.DownVotes, pwv.UniqueVoterCount
), 
ClosedPosts AS (
    SELECT DISTINCT 
        p.Id AS ClosedPostId,
        ph.Comment AS CloseReason
    FROM 
        Posts p
    JOIN 
        PostHistory ph ON p.Id = ph.PostId
    WHERE 
        ph.PostHistoryTypeId = 10 AND ph.Comment IS NOT NULL
)
SELECT 
    pwc.PostId,
    pwc.Title,
    pwc.CreationDate,
    pwc.ViewCount,
    pwc.Score,
    pwc.UpVotes,
    pwc.DownVotes,
    pwc.UniqueVoterCount,
    pwc.CommentCount,
    cp.CloseReason
FROM 
    PostsWithComments pwc
LEFT JOIN 
    ClosedPosts cp ON pwc.PostId = cp.ClosedPostId
WHERE 
    (pwc.CommentCount > 0 OR cp.CloseReason IS NOT NULL)
ORDER BY 
    pwc.Score DESC,
    pwc.CreationDate ASC
LIMIT 100;
