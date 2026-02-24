
WITH RecursivePostHistory AS (
    SELECT 
        ph.Id AS PostHistoryId,
        ph.PostId,
        ph.PostHistoryTypeId,
        ph.CreationDate,
        ph.UserId,
        ph.Comment,
        ROW_NUMBER() OVER (PARTITION BY ph.PostId ORDER BY ph.CreationDate DESC) AS rn
    FROM 
        PostHistory ph
),
UserReputation AS (
    SELECT 
        u.Id AS UserId,
        u.Reputation,
        COUNT(b.Id) AS BadgeCount,
        SUM(CASE WHEN b.Class = 1 THEN 1 ELSE 0 END) AS GoldBadges,
        SUM(CASE WHEN b.Class = 2 THEN 1 ELSE 0 END) AS SilverBadges,
        SUM(CASE WHEN b.Class = 3 THEN 1 ELSE 0 END) AS BronzeBadges
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id, u.Reputation
),
PopularTags AS (
    SELECT 
        t.TagName,
        SUM(p.ViewCount) AS TotalViews,
        COUNT(p.Id) AS PostCount
    FROM 
        Tags t
    JOIN 
        Posts p ON t.Id = p.Id  
    GROUP BY 
        t.TagName
    HAVING 
        COUNT(p.Id) > 5  
),
PostScores AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        COALESCE(ps.TotalViews, 0) AS TotalViews,
        COUNT(c.Id) AS CommentCount,
        SUM(v.BountyAmount) AS TotalBounty
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    LEFT JOIN 
        PopularTags ps ON p.Tags LIKE '%' || ps.TagName || '%'  
    WHERE 
        p.CreationDate >= CAST('2024-10-01 12:34:56' AS TIMESTAMP) - INTERVAL '30 days'  
    GROUP BY 
        p.Id, p.Title, p.Score, ps.TotalViews
),
RankedPosts AS (
    SELECT 
        ps.PostId,
        ps.Title,
        ps.Score,
        ps.TotalViews,
        ps.CommentCount,
        ps.TotalBounty,
        RANK() OVER (ORDER BY ps.Score DESC, ps.TotalViews DESC) AS PostRank
    FROM 
        PostScores ps
),
FinalOutput AS (
    SELECT 
        rp.*,
        u.DisplayName AS PostOwner,
        COALESCE(uRep.Reputation, 0) AS OwnerReputation,
        ph.Comment AS LastEditComment
    FROM 
        RankedPosts rp
    LEFT JOIN 
        Posts p ON rp.PostId = p.Id
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        UserReputation uRep ON u.Id = uRep.UserId
    LEFT JOIN 
        RecursivePostHistory ph ON p.Id = ph.PostId AND ph.rn = 1
)

SELECT 
    *
FROM 
    FinalOutput
WHERE 
    OwnerReputation > 1000  
ORDER BY 
    PostRank
LIMIT 10;
