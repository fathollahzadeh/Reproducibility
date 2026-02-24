
WITH RankedPosts AS (
    SELECT 
        p.Id,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        p.AnswerCount,
        p.OwnerUserId,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS rn
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1 
        AND p.CreationDate > TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 year'
),
UserBadges AS (
    SELECT 
        b.UserId,
        COUNT(CASE WHEN b.Class = 1 THEN 1 END) AS GoldBadges,
        COUNT(CASE WHEN b.Class = 2 THEN 1 END) AS SilverBadges,
        COUNT(CASE WHEN b.Class = 3 THEN 1 END) AS BronzeBadges
    FROM 
        Badges b
    GROUP BY 
        b.UserId
),
PostVoteStats AS (
    SELECT 
        v.PostId,
        SUM(CASE WHEN vt.Name = 'UpMod' THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN vt.Name = 'DownMod' THEN 1 ELSE 0 END) AS DownVotes
    FROM 
        Votes v
    JOIN 
        VoteTypes vt ON v.VoteTypeId = vt.Id
    GROUP BY 
        v.PostId
),
MostActiveUsers AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COALESCE(SUM(p.ViewCount), 0) AS TotalViews,
        COALESCE(SUM(p.AnswerCount), 0) AS TotalAnswers
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    WHERE 
        u.Reputation > 1000 
    GROUP BY 
        u.Id, u.DisplayName
),
FinalResults AS (
    SELECT 
        rp.Title,
        u.DisplayName AS OwnerDisplayName,
        ub.GoldBadges,
        ub.SilverBadges,
        ub.BronzeBadges,
        pvs.UpVotes,
        pvs.DownVotes,
        mau.TotalViews,
        mau.TotalAnswers
    FROM 
        RankedPosts rp
    JOIN 
        Users u ON rp.OwnerUserId = u.Id
    LEFT JOIN 
        UserBadges ub ON u.Id = ub.UserId
    LEFT JOIN 
        PostVoteStats pvs ON rp.Id = pvs.PostId
    LEFT JOIN 
        MostActiveUsers mau ON mau.UserId = u.Id
    WHERE 
        rp.rn = 1 
)

SELECT 
    *,
    CASE 
        WHEN GoldBadges > 0 THEN 'Gold Holder'
        WHEN SilverBadges > 0 THEN 'Silver Holder'
        ELSE 'No Badges'
    END AS BadgeStatus,
    COALESCE((UpVotes - DownVotes), 0) AS VoteBalance
FROM 
    FinalResults
ORDER BY 
    TotalViews DESC
LIMIT 10;
