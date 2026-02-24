
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        COALESCE((
            SELECT COUNT(*)
            FROM Votes v
            WHERE v.PostId = p.Id AND v.VoteTypeId = 2  
        ), 0) AS UpVotes,
        COALESCE((
            SELECT COUNT(*)
            FROM Votes v
            WHERE v.PostId = p.Id AND v.VoteTypeId = 3  
        ), 0) AS DownVotes,
        p.CreationDate,
        ROW_NUMBER() OVER (ORDER BY p.CreationDate DESC) AS RowNum
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1  
),
AggregateVotes AS (
    SELECT 
        PostId,
        SUM(UpVotes) AS TotalUpVotes,
        SUM(DownVotes) AS TotalDownVotes
    FROM 
        RankedPosts
    GROUP BY 
        PostId
),
PostHistoryInfo AS (
    SELECT 
        ph.PostId,
        ph.UserDisplayName,
        ph.CreationDate,
        ph.Comment,
        p.Title
    FROM 
        PostHistory ph
    JOIN 
        Posts p ON ph.PostId = p.Id
    WHERE 
        ph.PostHistoryTypeId IN (10, 11)  
),
FinalReport AS (
    SELECT 
        r.PostId,
        r.Title,
        a.TotalUpVotes,
        a.TotalDownVotes,
        p.UserDisplayName AS LastUser,
        p.CreationDate AS LastEditDate
    FROM 
        RankedPosts r
    JOIN 
        AggregateVotes a ON r.PostId = a.PostId
    LEFT JOIN 
        PostHistoryInfo p ON r.PostId = p.PostId
    WHERE 
        r.RowNum <= 100  
)
SELECT 
    f.PostId,
    f.Title,
    f.TotalUpVotes,
    f.TotalDownVotes,
    COALESCE(f.LastUser, 'No edits') AS LastEditedBy,
    f.LastEditDate,
    CASE 
        WHEN f.TotalDownVotes > f.TotalUpVotes THEN 'Needs Attention'
        WHEN f.TotalUpVotes > f.TotalDownVotes THEN 'Popular'
        ELSE 'Neutral'
    END AS PostStatus
FROM 
    FinalReport f
ORDER BY 
    f.TotalUpVotes DESC, f.LastEditDate DESC;
