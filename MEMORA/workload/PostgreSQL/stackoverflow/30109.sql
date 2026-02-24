
WITH RankedPosts AS (
    SELECT 
        p.Id,
        p.Title,
        u.DisplayName AS OwnerName,
        COUNT(DISTINCT c.Id) AS CommentCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS PostRank
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.CreationDate >= (CAST('2024-10-01 12:34:56' AS TIMESTAMP) - INTERVAL '1 year')
    GROUP BY 
        p.Id, p.Title, u.DisplayName
),
TopQuestions AS (
    SELECT 
        Id,
        Title,
        OwnerName,
        CommentCount,
        UpVotes,
        DownVotes
    FROM 
        RankedPosts
    WHERE 
        PostRank <= 10
),
RecentPostHistory AS (
    SELECT 
        ph.PostId,
        ph.PostHistoryTypeId,
        ph.CreationDate,
        ph.UserDisplayName,
        ph.Comment,
        RANK() OVER (PARTITION BY ph.PostId ORDER BY ph.CreationDate DESC) AS HistoryRank
    FROM 
        PostHistory ph
    WHERE 
        ph.CreationDate >= (CAST('2024-10-01 12:34:56' AS TIMESTAMP) - INTERVAL '1 month')
)
SELECT 
    tq.Title,
    tq.OwnerName,
    tq.CommentCount,
    tq.UpVotes,
    tq.DownVotes,
    COALESCE(rp.HistoryComments, 'No recent changes') AS RecentChanges
FROM 
    TopQuestions tq
LEFT JOIN (
    SELECT 
        PostId,
        STRING_AGG(CONCAT(UserDisplayName, ': ', Comment), '; ') AS HistoryComments
    FROM 
        RecentPostHistory
    WHERE 
        HistoryRank = 1
    GROUP BY 
        PostId
) rp ON tq.Id = rp.PostId
ORDER BY 
    tq.UpVotes DESC, tq.CommentCount DESC;
