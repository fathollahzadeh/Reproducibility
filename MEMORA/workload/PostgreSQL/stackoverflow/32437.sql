
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        p.Tags,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS PostRank,
        p.OwnerUserId
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1 
        AND p.Score > 0 
),
UserStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS QuestionCount,
        SUM(COALESCE(p.Score, 0)) AS TotalScore,
        SUM(COALESCE(b.Class, 0)) AS TotalBadges
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId AND p.PostTypeId = 1
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id, u.DisplayName
),
PostHistoryDetails AS (
    SELECT 
        ph.PostId,
        ph.PostHistoryTypeId,
        ph.CreationDate AS HistoryDate,
        CONCAT(u.DisplayName, ': ', ph.Comment) AS HistoryComment
    FROM 
        PostHistory ph
    JOIN 
        Users u ON ph.UserId = u.Id
    WHERE 
        ph.PostHistoryTypeId IN (10, 11) 
),
TopRankedPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.Score,
        rp.ViewCount,
        us.UserId,
        us.DisplayName,
        us.QuestionCount,
        us.TotalScore,
        us.TotalBadges
    FROM 
        RankedPosts rp
    JOIN 
        UserStats us ON rp.OwnerUserId = us.UserId
    WHERE 
        rp.PostRank <= 3 
)
SELECT 
    trp.Title AS PostTitle,
    trp.Score AS PostScore,
    trp.ViewCount AS PostViewCount,
    trp.DisplayName AS OwnerName,
    trp.QuestionCount AS OwnerTotalQuestions,
    trp.TotalScore AS OwnerTotalScore,
    trp.TotalBadges AS OwnerTotalBadges,
    COALESCE(phd.HistoryComment, 'No closure history') AS ClosureHistory
FROM 
    TopRankedPosts trp
LEFT JOIN 
    PostHistoryDetails phd ON trp.PostId = phd.PostId
ORDER BY 
    trp.Score DESC, trp.ViewCount DESC;
