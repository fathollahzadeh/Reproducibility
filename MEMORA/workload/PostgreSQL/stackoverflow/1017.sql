
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        u.DisplayName AS Owner,
        COUNT(c.Id) AS CommentCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS RN
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId 
    WHERE 
        p.PostTypeId = 1 
    GROUP BY 
        p.Id, u.DisplayName, p.CreationDate, p.OwnerUserId
),
RecentPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.Owner,
        rp.CommentCount,
        (rp.UpVotes - rp.DownVotes) AS NetScore
    FROM 
        RankedPosts rp
    WHERE 
        rp.RN = 1
),
HighScoringPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.Owner,
        rp.CommentCount,
        rp.NetScore
    FROM 
        RecentPosts rp
    WHERE 
        rp.NetScore > 0
)
SELECT 
    hsp.PostId,
    hsp.Title,
    hsp.Owner,
    hsp.CommentCount,
    hsp.NetScore,
    COALESCE((SELECT STRING_AGG(TagName, ', ') FROM Tags t 
               JOIN Posts p ON p.Id = t.ExcerptPostId 
               WHERE p.Id = hsp.PostId), 'No Tags') AS Tags
FROM 
    HighScoringPosts hsp
ORDER BY 
    hsp.NetScore DESC, hsp.CommentCount DESC
FETCH FIRST 10 ROWS ONLY;
