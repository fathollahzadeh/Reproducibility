
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.OwnerUserId,
        p.CreationDate,
        p.LastActivityDate,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS ScoreRank,
        COUNT(c.Id) AS CommentCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS Upvotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS Downvotes,
        COALESCE(u.Reputation, 0) AS UserReputation
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.CreationDate >= CURRENT_DATE - INTERVAL '1 year' 
    GROUP BY 
        p.Id, p.Title, p.OwnerUserId, p.CreationDate, p.LastActivityDate, u.Reputation
),
TopPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.OwnerUserId,
        rp.CreationDate,
        rp.LastActivityDate,
        rp.CommentCount,
        rp.Upvotes,
        rp.Downvotes,
        rp.UserReputation
    FROM 
        RankedPosts rp
    WHERE 
        rp.ScoreRank <= 5 
),
PostHistoryAnalysis AS (
    SELECT 
        ph.PostId,
        PHT.Name AS HistoryType,
        COUNT(*) AS HistoryCount,
        MIN(ph.CreationDate) AS FirstHistoryDate,
        MAX(ph.CreationDate) AS LastHistoryDate
    FROM 
        PostHistory ph
    JOIN 
        PostHistoryTypes PHT ON ph.PostHistoryTypeId = PHT.Id
    GROUP BY 
        ph.PostId, PHT.Name
),
UserBadges AS (
    SELECT 
        b.UserId,
        COUNT(*) AS TotalBadges,
        SUM(CASE WHEN b.Class = 1 THEN 1 ELSE 0 END) AS GoldBadges,
        SUM(CASE WHEN b.Class = 2 THEN 1 ELSE 0 END) AS SilverBadges,
        SUM(CASE WHEN b.Class = 3 THEN 1 ELSE 0 END) AS BronzeBadges
    FROM 
        Badges b
    GROUP BY 
        b.UserId
)
SELECT 
    tp.Title,
    tp.CommentCount,
    tp.Upvotes,
    tp.Downvotes,
    COALESCE(uba.TotalBadges, 0) AS TotalBadges,
    COALESCE(uba.GoldBadges, 0) AS GoldBadges,
    COALESCE(uba.SilverBadges, 0) AS SilverBadges,
    COALESCE(uba.BronzeBadges, 0) AS BronzeBadges,
    pha.HistoryType,
    pha.HistoryCount,
    pha.FirstHistoryDate,
    pha.LastHistoryDate
FROM 
    TopPosts tp
LEFT JOIN 
    UserBadges uba ON tp.OwnerUserId = uba.UserId
LEFT JOIN 
    PostHistoryAnalysis pha ON tp.PostId = pha.PostId
ORDER BY 
    tp.LastActivityDate DESC, tp.Upvotes DESC;
