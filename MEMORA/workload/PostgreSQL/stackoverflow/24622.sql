WITH UserMetrics AS (
    SELECT 
        u.Id AS UserId,
        u.Reputation,
        u.CreationDate,
        u.DisplayName,
        COUNT(b.Id) AS BadgeCount,
        SUM(CASE WHEN b.Class = 1 THEN 1 ELSE 0 END) AS GoldBadges,
        SUM(CASE WHEN b.Class = 2 THEN 1 ELSE 0 END) AS SilverBadges,
        SUM(CASE WHEN b.Class = 3 THEN 1 ELSE 0 END) AS BronzeBadges
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id, u.Reputation, u.CreationDate, u.DisplayName
),
PostDetails AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.OwnerUserId,
        COALESCE(pt.Name, 'Unknown') AS PostType,
        SUM(COALESCE(vs.vote_count, 0)) AS TotalVotes,
        COUNT(DISTINCT c.Id) AS CommentCount,
        COUNT(DISTINCT p2.Id) AS RelatedPostsCount
    FROM 
        Posts p
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    LEFT JOIN 
        (SELECT 
            PostId, COUNT(*) AS vote_count 
         FROM 
            Votes 
         GROUP BY 
            PostId) AS vs ON p.Id = vs.PostId
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        PostLinks pl ON p.Id = pl.PostId
    LEFT JOIN 
        Posts p2 ON pl.RelatedPostId = p2.Id
    LEFT JOIN 
        PostTypes pt ON p.PostTypeId = pt.Id
    WHERE 
        p.CreationDate >= cast('2024-10-01' as date) - INTERVAL '1 year'
    GROUP BY 
        p.Id, pt.Name
),
RankedPosts AS (
    SELECT 
        pd.*,
        RANK() OVER (PARTITION BY pd.OwnerUserId ORDER BY pd.TotalVotes DESC) AS VoteRank
    FROM 
        PostDetails pd
),
FinalMetrics AS (
    SELECT 
        um.UserId,
        um.DisplayName,
        um.Reputation,
        rp.Title,
        rp.PostId,
        rp.PostType,
        rp.CreationDate,
        rp.TotalVotes,
        rp.CommentCount,
        rp.RelatedPostsCount,
        rp.VoteRank
    FROM 
        UserMetrics um
    LEFT JOIN 
        RankedPosts rp ON um.UserId = rp.OwnerUserId
    WHERE 
        (um.Reputation > 1000 OR rp.TotalVotes > 5) AND 
        (rp.PostType != 'Unknown' OR rp.CommentCount > 0)
)
SELECT 
    *,
    CASE 
        WHEN VoteRank IS NULL THEN 'No Posts'
        WHEN VoteRank <= 3 THEN 'Top Contributor'
        ELSE 'Contributor'
    END AS ContributorStatus
FROM 
    FinalMetrics
ORDER BY 
    Reputation DESC, TotalVotes DESC;