
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        RANK() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS PostRank,
        COALESCE(u.DisplayName, 'Community User') AS OwnerName,
        COUNT(c.Id) AS CommentCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.ViewCount, u.DisplayName, p.PostTypeId
),
PostHistoryInfo AS (
    SELECT 
        ph.PostId,
        ph.PostHistoryTypeId,
        ph.UserDisplayName,
        ph.CreationDate,
        ph.Comment,
        ROW_NUMBER() OVER (PARTITION BY ph.PostId ORDER BY ph.CreationDate DESC) AS ChangeRank
    FROM 
        PostHistory ph
    WHERE 
        ph.PostHistoryTypeId IN (10, 12, 14, 20)
),
FilteredPostHistory AS (
    SELECT 
        ph.PostId,
        STRING_AGG(ph.Comment, ', ') AS RecentChanges
    FROM 
        PostHistoryInfo ph
    WHERE 
        ph.ChangeRank <= 3
    GROUP BY 
        ph.PostId
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.CreationDate,
    rp.ViewCount,
    rp.OwnerName,
    rp.CommentCount,
    rp.UpVotes,
    rp.DownVotes,
    fph.RecentChanges
FROM 
    RankedPosts rp
LEFT JOIN 
    FilteredPostHistory fph ON rp.PostId = fph.PostId
WHERE 
    rp.PostRank = 1
    AND (rp.ViewCount > 100 OR rp.CommentCount > 5)
ORDER BY 
    rp.ViewCount DESC, rp.CommentCount DESC
FETCH FIRST 100 ROWS ONLY;
