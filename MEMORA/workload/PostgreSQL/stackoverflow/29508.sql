
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.Tags,
        u.DisplayName AS OwnerDisplayName,
        p.CreationDate,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS PostRank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.CreationDate >= CURRENT_DATE - INTERVAL '1 year'
),
PostStats AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.Body,
        rp.Tags,
        rp.OwnerDisplayName,
        rp.CreationDate,
        COALESCE(COUNT(c.Id), 0) AS CommentCount,
        COALESCE(SUM(v.BountyAmount), 0) AS TotalBounties,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS UpVotes,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS DownVotes
    FROM 
        RankedPosts rp
    LEFT JOIN 
        Comments c ON rp.PostId = c.PostId
    LEFT JOIN 
        Votes v ON rp.PostId = v.PostId
    GROUP BY 
        rp.PostId, rp.Title, rp.Body, rp.Tags, rp.OwnerDisplayName, rp.CreationDate
),
FilteredPosts AS (
    SELECT 
        ps.*,
        ROW_NUMBER() OVER (ORDER BY ps.UpVotes - ps.DownVotes DESC, ps.CommentCount DESC, ps.TotalBounties DESC) AS ScoreRank
    FROM 
        PostStats ps
    WHERE 
        ps.CommentCount > 0 
)
SELECT 
    fp.PostId,
    fp.Title,
    fp.Body,
    fp.Tags,
    fp.OwnerDisplayName,
    fp.CreationDate,
    fp.UpVotes,
    fp.DownVotes,
    fp.CommentCount,
    fp.TotalBounties,
    fp.ScoreRank
FROM 
    FilteredPosts fp
WHERE 
    fp.ScoreRank <= 10 
ORDER BY 
    fp.ScoreRank;
