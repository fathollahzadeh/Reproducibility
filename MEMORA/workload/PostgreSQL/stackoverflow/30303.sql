
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        u.DisplayName AS OwnerDisplayName,
        COALESCE(NULLIF(p.AcceptedAnswerId, -1), 0) AS AcceptedAnswerId,
        COUNT(DISTINCT c.Id) AS CommentCount,
        COUNT(DISTINCT v.Id) AS VoteCount
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.PostTypeId = 1 
    GROUP BY 
        p.Id, p.Title, p.CreationDate, u.DisplayName
),

PostHistoryDetails AS (
    SELECT 
        ph.PostId,
        STRING_AGG(DISTINCT pht.Name, ', ') AS HistoryTypes,
        MAX(ph.CreationDate) AS LastModifiedDate
    FROM 
        PostHistory ph
    JOIN 
        PostHistoryTypes pht ON ph.PostHistoryTypeId = pht.Id
    GROUP BY 
        ph.PostId
),

PostRankings AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.OwnerDisplayName,
        rp.CreationDate,
        COALESCE(phd.HistoryTypes, 'No history') AS HistoryDetails,
        rp.CommentCount,
        rp.VoteCount,
        ROW_NUMBER() OVER (ORDER BY rp.VoteCount DESC, rp.CommentCount DESC) AS PostRank
    FROM 
        RankedPosts rp
    LEFT JOIN 
        PostHistoryDetails phd ON rp.PostId = phd.PostId
)

SELECT 
    pr.PostId,
    pr.Title,
    pr.OwnerDisplayName,
    pr.CreationDate,
    pr.HistoryDetails,
    pr.CommentCount,
    pr.VoteCount,
    pr.PostRank,
    CASE 
        WHEN pr.VoteCount = 0 THEN 'No Votes Yet'
        ELSE CONCAT(pr.OwnerDisplayName, ' has received ', CAST(pr.VoteCount AS VARCHAR), ' votes.')
    END AS VoteMessage
FROM 
    PostRankings pr
WHERE 
    pr.PostRank <= 10 
ORDER BY 
    pr.VoteCount DESC, pr.CommentCount DESC;
