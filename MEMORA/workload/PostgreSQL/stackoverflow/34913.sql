
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        p.PostTypeId,
        u.DisplayName AS OwnerDisplayName,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC, p.ViewCount DESC) AS Rank,
        COUNT(v.Id) AS VoteCount,
        (SELECT COUNT(c.Id) FROM Comments c WHERE c.PostId = p.Id) AS CommentCount,
        COALESCE(NULLIF(p.AcceptedAnswerId, -1), -1) AS AcceptedAnswerId
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Votes v ON v.PostId = p.Id
    WHERE 
        p.CreationDate >= '2023-01-01'
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.ViewCount, p.Score, p.PostTypeId, u.DisplayName
), RecentActivity AS (
    SELECT 
        PostId,
        MAX(CreationDate) AS LastActivityDate
    FROM 
        Comments
    GROUP BY 
        PostId
), PostDetails AS (
    SELECT 
        rp.*,
        ra.LastActivityDate,
        CASE WHEN rp.AcceptedAnswerId != -1 THEN 'Yes' ELSE 'No' END AS HasAcceptedAnswer
    FROM 
        RankedPosts rp
    LEFT JOIN 
        RecentActivity ra ON rp.PostId = ra.PostId
)
SELECT 
    pd.PostId,
    pd.Title,
    pd.CreationDate,
    pd.ViewCount,
    pd.Score,
    pd.OwnerDisplayName,
    pd.Rank,
    pd.VoteCount,
    pd.CommentCount,
    pd.LastActivityDate,
    pd.HasAcceptedAnswer,
    CONCAT('Post Title: ', pd.Title, ' | Owner: ', pd.OwnerDisplayName) AS PostSummary
FROM 
    PostDetails pd
WHERE 
    pd.Rank <= 5
ORDER BY 
    pd.Score DESC, 
    pd.ViewCount DESC;
