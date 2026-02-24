WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.OwnerUserId,
        p.CreationDate,
        p.Score,
        COUNT(DISTINCT c.Id) AS CommentCount,
        COUNT(DISTINCT a.Id) AS AnswerCount,
        RANK() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC, p.CreationDate DESC) AS PostRank
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Posts a ON p.Id = a.ParentId AND a.PostTypeId = 2
    WHERE 
        p.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year' 
    GROUP BY 
        p.Id, p.Title, p.OwnerUserId, p.CreationDate, p.Score, p.PostTypeId
),

TopPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.OwnerUserId,
        rp.Score,
        rp.CommentCount,
        rp.AnswerCount,
        rp.PostRank,
        u.Reputation,
        u.DisplayName,
        CASE 
            WHEN u.Location IS NOT NULL THEN CONCAT('Located in: ', u.Location)
            ELSE 'Location not specified'
        END AS UserLocation
    FROM 
        RankedPosts rp
    JOIN 
        Users u ON rp.OwnerUserId = u.Id
    WHERE 
        rp.PostRank <= 5
),

PostHistoryDetails AS (
    SELECT 
        ph.PostId, 
        ph.CreationDate AS HistoryDate,
        pht.Name AS PostHistoryType,
        ph.UserDisplayName,
        ph.Text
    FROM 
        PostHistory ph
    JOIN 
        PostHistoryTypes pht ON ph.PostHistoryTypeId = pht.Id
    WHERE 
        ph.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 month'
)

SELECT 
    tp.PostId,
    tp.Title,
    tp.Score,
    tp.CommentCount,
    tp.AnswerCount,
    tp.Reputation AS UserReputation,
    tp.DisplayName AS OwnerDisplayName,
    tp.UserLocation,
    pht.HistoryDate,
    pht.PostHistoryType,
    pht.UserDisplayName AS EditorName,
    pht.Text AS EditDetails
FROM 
    TopPosts tp
LEFT JOIN 
    PostHistoryDetails pht ON tp.PostId = pht.PostId
ORDER BY 
    tp.Score DESC, tp.PostId;