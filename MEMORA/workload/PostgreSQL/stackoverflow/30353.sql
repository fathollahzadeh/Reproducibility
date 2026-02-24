
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        p.OwnerUserId,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS RowNum
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1  
),
PostStats AS (
    SELECT 
        p.Id AS PostId,
        COUNT(c.Id) AS CommentCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.PostTypeId = 1 
    GROUP BY 
        p.Id
),
TopPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.CreationDate,
        ps.CommentCount,
        ps.UpVotes,
        ps.DownVotes,
        (ps.UpVotes - ps.DownVotes) AS ScoreDifference,
        CASE 
            WHEN ps.UpVotes >= 10 THEN 'High Engagement'
            WHEN ps.UpVotes BETWEEN 5 AND 9 THEN 'Moderate Engagement'
            ELSE 'Low Engagement'
        END AS EngagementLevel
    FROM 
        RankedPosts rp
    JOIN 
        PostStats ps ON rp.PostId = ps.PostId
    WHERE 
        rp.RowNum <= 5  
),
PostHistoryData AS (
    SELECT 
        ph.PostId,
        ph.CreationDate,
        pht.Name AS ActionType,
        ph.UserId,
        u.DisplayName AS UserDisplayName,
        ph.Comment
    FROM 
        PostHistory ph
    JOIN 
        PostHistoryTypes pht ON ph.PostHistoryTypeId = pht.Id
    JOIN 
        Users u ON ph.UserId = u.Id
    WHERE 
        ph.PostHistoryTypeId IN (10, 11, 12)  
)
SELECT 
    tp.PostId,
    tp.Title,
    tp.CreationDate,
    tp.CommentCount,
    tp.UpVotes,
    tp.DownVotes,
    tp.ScoreDifference,
    tp.EngagementLevel,
    COUNT(pd.PostId) AS ActionCount,
    STRING_AGG(CONCAT(pd.ActionType, ' by ', pd.UserDisplayName, ' on ', pd.CreationDate), '; ') AS ActionHistory
FROM 
    TopPosts tp
LEFT JOIN 
    PostHistoryData pd ON tp.PostId = pd.PostId
GROUP BY 
    tp.PostId, tp.Title, tp.CreationDate, tp.CommentCount, tp.UpVotes, tp.DownVotes, tp.ScoreDifference, tp.EngagementLevel 
ORDER BY 
    tp.ScoreDifference DESC, tp.Title;
