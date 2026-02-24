
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.CreationDate DESC) AS Rank,
        COALESCE(NULLIF(p.AcceptedAnswerId, -1), 0) AS AcceptedAnswerId
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= CURRENT_DATE - INTERVAL '2 years'
),
UserStats AS (
    SELECT 
        u.Id AS UserId,
        u.Reputation,
        COALESCE(SUM(CASE WHEN b.Class = 1 THEN 1 ELSE 0 END), 0) AS GoldBadges, 
        COALESCE(SUM(CASE WHEN b.Class = 2 THEN 1 ELSE 0 END), 0) AS SilverBadges, 
        COALESCE(SUM(CASE WHEN b.Class = 3 THEN 1 ELSE 0 END), 0) AS BronzeBadges,
        COUNT(DISTINCT p.Id) AS PostCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON b.UserId = u.Id
    LEFT JOIN 
        Posts p ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Votes v ON v.UserId = u.Id
    GROUP BY 
        u.Id, u.Reputation
),
PostHistoryDetails AS (
    SELECT 
        ph.PostId,
        ph.Comment AS CloseComment,
        ph.CreationDate AS CloseDate,
        CONCAT(EXTRACT(YEAR FROM ph.CreationDate), '-', LPAD(EXTRACT(MONTH FROM ph.CreationDate)::TEXT, 2, '0')) AS CloseMonthYear
    FROM 
        PostHistory ph
    WHERE 
        ph.PostHistoryTypeId = 10 
),
FilteredPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.CreationDate,
        us.UserId,
        us.Reputation,
        pd.CloseComment,
        pd.CloseDate,
        pd.CloseMonthYear
    FROM 
        RankedPosts rp
    LEFT JOIN 
        UserStats us ON us.UserId = rp.AcceptedAnswerId
    LEFT JOIN 
        PostHistoryDetails pd ON pd.PostId = rp.PostId
    WHERE 
        rp.Rank <= 5
)
SELECT 
    fp.PostId,
    fp.Title,
    fp.CreationDate,
    fp.Reputation,
    CASE 
        WHEN fp.CloseComment IS NOT NULL THEN 'Closed'
        ELSE 'Open'
    END AS PostStatus,
    COALESCE(fp.CloseMonthYear, 'Not Closed') AS ClosedMonthYear,
    (SELECT STRING_AGG(DISTINCT t.TagName, ', ') 
     FROM Tags t
     JOIN Posts p ON t.ExcerptPostId = p.Id 
     WHERE p.Id = fp.PostId) AS AssociatedTags
FROM 
    FilteredPosts fp
ORDER BY 
    fp.CreationDate DESC;
