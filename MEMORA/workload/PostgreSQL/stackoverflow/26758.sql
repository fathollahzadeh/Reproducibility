WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        p.OwnerUserId,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC, p.ViewCount DESC) AS Rank
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1 AND  
        p.CreationDate >= (cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year')  
),
UserEngagement AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(distinct p.Id) AS QuestionsAsked,
        SUM(COALESCE(b.Class, 0)) AS TotalBadges,
        SUM(v.BountyAmount) AS TotalBounty
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId AND p.PostTypeId = 1  
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    LEFT JOIN 
        Votes v ON u.Id = v.UserId
    GROUP BY 
        u.Id, u.DisplayName
),
TopEngagedUsers AS (
    SELECT 
        ue.UserId,
        ue.DisplayName,
        ue.QuestionsAsked,
        ue.TotalBadges,
        ue.TotalBounty,
        ROW_NUMBER() OVER (ORDER BY ue.QuestionsAsked DESC, ue.TotalBounty DESC) AS EngagementRank
    FROM 
        UserEngagement ue
    WHERE 
        ue.QuestionsAsked > 0 
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.CreationDate,
    rp.ViewCount,
    rp.Score,
    ue.DisplayName AS OwnerDisplayName,
    ue.QuestionsAsked,
    ue.TotalBadges,
    ue.TotalBounty
FROM 
    RankedPosts rp
JOIN 
    TopEngagedUsers ue ON rp.OwnerUserId = ue.UserId
WHERE 
    ue.EngagementRank <= 10  
ORDER BY 
    rp.CreationDate DESC;