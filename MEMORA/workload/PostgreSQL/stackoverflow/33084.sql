
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        u.DisplayName AS OwnerName,
        COUNT(c.Id) AS CommentCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS PostRank
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    GROUP BY 
        p.Id, p.Title, p.CreationDate, u.DisplayName
),
PostHistoryWithFlags AS (
    SELECT 
        ph.PostId,
        MAX(CASE WHEN ph.PostHistoryTypeId = 10 THEN 1 ELSE 0 END) AS IsClosed,
        MAX(CASE WHEN ph.PostHistoryTypeId = 11 THEN 1 ELSE 0 END) AS IsReopened,
        MAX(CASE WHEN ph.PostHistoryTypeId = 12 THEN 1 ELSE 0 END) AS IsDeleted
    FROM 
        PostHistory ph
    GROUP BY 
        ph.PostId
),
FilteredPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.CreationDate,
        rp.OwnerName,
        rp.CommentCount,
        rp.UpVotes,
        rp.DownVotes,
        phwf.IsClosed,
        phwf.IsReopened,
        phwf.IsDeleted
    FROM 
        RankedPosts rp
    JOIN 
        PostHistoryWithFlags phwf ON rp.PostId = phwf.PostId
    WHERE 
        rp.PostRank <= 5 AND 
        phwf.IsClosed = 0 AND 
        phwf.IsDeleted = 0
)
SELECT 
    p.Title,
    p.OwnerName,
    p.CommentCount,
    p.UpVotes,
    p.DownVotes,
    p.CreationDate,
    EXTRACT(EPOCH FROM (TIMESTAMP '2024-10-01 12:34:56' - p.CreationDate)) AS AgeInSeconds
FROM 
    FilteredPosts p
ORDER BY 
    p.UpVotes DESC, 
    p.CommentCount DESC
LIMIT 10;
