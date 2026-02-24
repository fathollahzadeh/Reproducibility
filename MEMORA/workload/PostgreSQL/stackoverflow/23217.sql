WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.AnswerCount,
        p.ViewCount,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.CreationDate DESC) AS RN,
        SUM(p.ViewCount) OVER (PARTITION BY p.PostTypeId) AS TotalViews
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= cast('2024-10-01' as date) - INTERVAL '1 year'
), 
UserActivity AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT v.PostId) AS VoteCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
        COALESCE(SUM(CASE WHEN b.Class = 1 THEN 1 ELSE 0 END), 0) AS GoldBadges
    FROM 
        Users u
    LEFT JOIN 
        Votes v ON u.Id = v.UserId
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id
),
PostHistoryInfo AS (
    SELECT 
        ph.PostId,
        ph.PostHistoryTypeId,
        MIN(ph.CreationDate) AS FirstActionDate,
        STRING_AGG(CONCAT('User:', ph.UserId, ' Action:', ph.Comment), '; ') AS HistoryComments
    FROM 
        PostHistory ph
    GROUP BY 
        ph.PostId, ph.PostHistoryTypeId
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.CreationDate AS PostCreationDate,
    rp.Score,
    rp.AnswerCount,
    rp.ViewCount,
    rp.TotalViews,
    ua.DisplayName AS Creator,
    ua.VoteCount,
    ua.UpVotes,
    ua.DownVotes,
    ua.GoldBadges,
    pht.FirstActionDate,
    pht.HistoryComments
FROM 
    RankedPosts rp
JOIN 
    UserActivity ua ON rp.PostId = ua.UserId
LEFT JOIN 
    PostHistoryInfo pht ON rp.PostId = pht.PostId
WHERE 
    rp.RN = 1
    AND (pht.FirstActionDate IS NULL OR pht.FirstActionDate < rp.CreationDate)
ORDER BY 
    rp.TotalViews DESC, 
    rp.Score DESC
LIMIT 100;