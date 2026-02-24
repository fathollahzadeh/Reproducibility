WITH 
    RankedPosts AS (
        SELECT 
            p.Id AS PostId,
            p.OwnerUserId,
            p.PostTypeId,
            p.Title,
            p.CreationDate,
            COUNT(a.Id) AS AnswerCount,
            ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY COUNT(a.Id) DESC) AS UserPostRank
        FROM 
            Posts p
        LEFT JOIN 
            Posts a ON p.Id = a.ParentId AND a.PostTypeId = 2
        WHERE 
            p.PostTypeId = 1 
        GROUP BY 
            p.Id, p.OwnerUserId, p.PostTypeId, p.Title, p.CreationDate
    ),
    UserBadges AS (
        SELECT 
            b.UserId,
            STRING_AGG(b.Name, ', ') AS BadgeNames,
            COUNT(b.Id) AS BadgeCount,
            MAX(b.Date) AS LatestBadgeDate
        FROM 
            Badges b
        GROUP BY 
            b.UserId
    ),
    AggregateVotes AS (
        SELECT 
            v.PostId,
            SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 WHEN v.VoteTypeId = 3 THEN -1 ELSE 0 END) AS VoteScore,
            COUNT(CASE WHEN v.VoteTypeId IN (1, 2, 5) THEN 1 END) AS PositiveVotes
        FROM 
            Votes v
        GROUP BY 
            v.PostId
    ),
    CombinedData AS (
        SELECT 
            rp.PostId,
            rp.OwnerUserId,
            rp.Title,
            rp.CreationDate,
            COALESCE(ub.BadgeNames, 'No Badges') AS UserBadges,
            COALESCE(ag.VoteScore, 0) AS TotalVotes,
            COALESCE(ub.BadgeCount, 0) AS TotalBadges,
            rp.UserPostRank
        FROM 
            RankedPosts rp
        LEFT JOIN 
            UserBadges ub ON rp.OwnerUserId = ub.UserId
        LEFT JOIN 
            AggregateVotes ag ON rp.PostId = ag.PostId
    )
SELECT 
    cd.PostId,
    cd.Title,
    cd.CreationDate,
    cd.UserBadges,
    cd.TotalVotes,
    cd.TotalBadges,
    CASE 
        WHEN cd.TotalVotes > 0 THEN 'Positive'
        WHEN cd.TotalVotes < 0 THEN 'Negative'
        ELSE 'Neutral'
    END AS VoteStatus,
    CASE 
        WHEN cd.UserPostRank = 1 THEN 'Top contributor'
        WHEN cd.UserPostRank > 1 AND cd.UserPostRank <= 3 THEN 'Frequent contributor'
        ELSE 'New contributor'
    END AS ContributorStatus
FROM 
    CombinedData cd
ORDER BY 
    cd.TotalVotes DESC, cd.CreationDate DESC
OFFSET 0 ROWS FETCH NEXT 100 ROWS ONLY;

