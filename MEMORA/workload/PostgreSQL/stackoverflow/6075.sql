
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC, p.ViewCount DESC) AS Rank
    FROM 
        Posts p
    WHERE 
        p.PostTypeId IN (1, 2) AND
        p.CreationDate >= CURRENT_DATE - INTERVAL '1 year'
), UserVoteCounts AS (
    SELECT 
        v.PostId,
        COUNT(CASE WHEN v.VoteTypeId = 2 THEN 1 END) AS UpVotes,
        COUNT(CASE WHEN v.VoteTypeId = 3 THEN 1 END) AS DownVotes
    FROM 
        Votes v
    GROUP BY 
        v.PostId
), PostsWithVotes AS (
    SELECT 
        rp.PostId, 
        rp.Title, 
        rp.CreationDate, 
        rp.ViewCount, 
        rp.Score,
        uv.UpVotes,
        uv.DownVotes,
        rp.Rank
    FROM 
        RankedPosts rp
    LEFT JOIN 
        UserVoteCounts uv ON rp.PostId = uv.PostId
)
SELECT 
    pwv.PostId,
    pwv.Title,
    pwv.ViewCount,
    pwv.Score,
    COALESCE(pwv.UpVotes, 0) AS UpVotes,
    COALESCE(pwv.DownVotes, 0) AS DownVotes,
    pwv.Rank
FROM 
    PostsWithVotes pwv
WHERE 
    pwv.Rank <= 10
ORDER BY 
    pwv.Rank;
