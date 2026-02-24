
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        u.DisplayName AS Owner,
        COUNT(c.Id) AS CommentCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVoteCount,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVoteCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS rn
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.CreationDate >= CAST('2024-10-01 12:34:56' AS TIMESTAMP) - INTERVAL '1 year'
    GROUP BY 
        p.Id, p.Title, p.CreationDate, u.DisplayName
),
FilteredPosts AS (
    SELECT 
        *,
        (UpVoteCount - DownVoteCount) AS NetVoteCount
    FROM 
        RankedPosts
    WHERE 
        rn <= 5
)
SELECT 
    fp.PostId,
    fp.Title,
    fp.CreationDate,
    fp.Owner,
    fp.CommentCount,
    fp.UpVoteCount,
    fp.DownVoteCount,
    fp.NetVoteCount,
    CASE 
        WHEN fp.CommentCount IS NULL THEN 'No comments yet'
        ELSE 'Comments available'
    END AS CommentStatus,
    COALESCE(NULLIF(fp.Title, ''), 'Untitled Post') AS TitleDisplay
FROM 
    FilteredPosts fp
LEFT JOIN 
    PostHistory ph ON fp.PostId = ph.PostId
WHERE 
    ph.CreationDate = (
        SELECT MAX(ph2.CreationDate)
        FROM PostHistory ph2
        WHERE ph2.PostId = fp.PostId
        AND ph2.PostHistoryTypeId IN (10, 11) 
    )
ORDER BY 
    fp.NetVoteCount DESC, 
    fp.CommentCount DESC;
