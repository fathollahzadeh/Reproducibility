
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Tags,
        p.Body,
        p.CreationDate,
        p.OwnerUserId,
        CASE 
            WHEN p.PostTypeId = 1 THEN 'Question'
            WHEN p.PostTypeId = 2 THEN 'Answer'
            WHEN p.PostTypeId = 4 THEN 'TagWikiExcerpt'
            ELSE 'Other'
        END AS PostType,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS PostRank
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= '2024-10-01 12:34:56'::timestamp - INTERVAL '1 year'
),
UserReputation AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        COUNT(DISTINCT p.Id) AS PostCount,
        SUM(CASE WHEN b.Class = 1 THEN 1 ELSE 0 END) AS GoldBadges,
        SUM(CASE WHEN b.Class = 2 THEN 1 ELSE 0 END) AS SilverBadges,
        SUM(CASE WHEN b.Class = 3 THEN 1 ELSE 0 END) AS BronzeBadges
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id, u.DisplayName, u.Reputation
),
FilteredQuestions AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.Tags,
        rp.Body,
        ur.DisplayName,
        ur.Reputation,
        ur.PostCount,
        ur.GoldBadges,
        ur.SilverBadges,
        ur.BronzeBadges
    FROM 
        RankedPosts rp
    INNER JOIN 
        UserReputation ur ON rp.OwnerUserId = ur.UserId
    WHERE 
        rp.PostType = 'Question' 
        AND (LOWER(rp.Body) LIKE '%performance%' OR LOWER(rp.Body) LIKE '%benchmark%')
)
SELECT 
    fq.PostId,
    fq.Title,
    fq.Tags,
    fq.Body,
    fq.DisplayName AS AuthorName,
    fq.Reputation AS AuthorReputation,
    fq.PostCount AS TotalPosts,
    fq.GoldBadges AS GoldBadgeCount,
    fq.SilverBadges AS SilverBadgeCount,
    fq.BronzeBadges AS BronzeBadgeCount
FROM 
    FilteredQuestions fq
ORDER BY 
    fq.Reputation DESC,
    fq.PostId;
