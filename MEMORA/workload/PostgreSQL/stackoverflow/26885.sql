
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.Tags,
        p.CreationDate,
        p.ViewCount,
        p.AcceptedAnswerId,
        COUNT(c.Id) AS CommentCount,
        COUNT(v.Id) AS VoteCount,
        RANK() OVER (PARTITION BY p.OwnerUserId ORDER BY p.ViewCount DESC) AS PostRank
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.PostTypeId = 1 
    GROUP BY 
        p.Id, p.Title, p.Body, p.Tags, p.CreationDate, p.ViewCount, p.AcceptedAnswerId
),
TopContributors AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(p.Id) AS QuestionCount,
        COALESCE(SUM(v.BountyAmount), 0) AS TotalBounty,
        COALESCE(SUM(b.Class), 0) AS TotalBadges
    FROM 
        Users u
    JOIN 
        Posts p ON p.OwnerUserId = u.Id AND p.PostTypeId = 1
    LEFT JOIN 
        Votes v ON p.Id = v.PostId AND v.VoteTypeId IN (8, 9) 
    LEFT JOIN 
        Badges b ON b.UserId = u.Id
    GROUP BY 
        u.Id, u.DisplayName
),
HighRankedPosts AS (
    SELECT 
        rp.*, 
        u.DisplayName AS Author,
        (SELECT COUNT(*) FROM PostHistory ph WHERE ph.PostId = rp.PostId AND ph.PostHistoryTypeId = 10) AS CloseCount, 
        (SELECT COUNT(*) FROM PostHistory ph WHERE ph.PostId = rp.PostId AND ph.PostHistoryTypeId = 12) AS DeleteCount 
    FROM 
        RankedPosts rp
    JOIN 
        Users u ON rp.AcceptedAnswerId = u.Id
    WHERE 
        rp.PostRank <= 3 
)
SELECT 
    hrp.PostId,
    hrp.Title,
    hrp.Body,
    hrp.Tags,
    hrp.CreationDate,
    hrp.ViewCount,
    hrp.CommentCount,
    hrp.VoteCount,
    hrp.Author,
    tc.DisplayName AS TopContributor,
    tc.QuestionCount,
    tc.TotalBounty,
    tc.TotalBadges,
    hrp.CloseCount,
    hrp.DeleteCount
FROM 
    HighRankedPosts hrp
JOIN 
    TopContributors tc ON hrp.Author = tc.DisplayName
ORDER BY 
    hrp.ViewCount DESC, 
    hrp.CommentCount DESC;
