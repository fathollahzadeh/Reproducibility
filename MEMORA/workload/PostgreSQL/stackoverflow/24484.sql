WITH UserBadges AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(b.Id) AS TotalBadges,
        STRING_AGG(b.Name, ', ') AS BadgeNames
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id, u.DisplayName
),
AllPosts AS (
    SELECT 
        p.Id AS PostId,
        p.OwnerUserId,
        p.PostTypeId,
        p.Title,
        p.Tags,
        p.AcceptedAnswerId,
        COALESCE(Answered.Score, 0) AS AnswerScore,
        COALESCE(VotedDown.DownVoteCount, 0) AS DownVoteScore,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS UserPostRank
    FROM 
        Posts p
    LEFT JOIN 
        (SELECT 
            ParentId, 
            SUM(Score) AS Score
         FROM 
            Posts 
         WHERE 
            PostTypeId = 2 
         GROUP BY 
            ParentId) AS Answered ON p.Id = Answered.ParentId
    LEFT JOIN 
        (SELECT 
            PostId, 
            COUNT(*) AS DownVoteCount 
         FROM 
            Votes 
         WHERE 
            VoteTypeId = 3 
         GROUP BY 
            PostId) AS VotedDown ON p.Id = VotedDown.PostId
)
SELECT 
    ub.UserId,
    ub.DisplayName,
    ub.TotalBadges,
    ub.BadgeNames,
    ap.PostId,
    ap.Title,
    ap.Tags,
    CASE 
        WHEN ap.AcceptedAnswerId IS NOT NULL THEN 'Accepted' 
        ELSE 'Not Accepted' 
    END AS AnswerStatus,
    ap.AnswerScore,
    ap.DownVoteScore,
    ap.UserPostRank,
    CASE 
        WHEN ap.UserPostRank = 1 
        THEN 'Most Recent Post' 
        ELSE NULL 
    END AS PostRankStatus
FROM 
    UserBadges ub
JOIN 
    AllPosts ap ON ub.UserId = ap.OwnerUserId
WHERE 
    ub.TotalBadges > 0
    AND (ap.Tags LIKE '%SQL%' OR ap.Title ILIKE '%SQL%')
    AND NOT EXISTS (
        SELECT 1
        FROM Comments c
        WHERE c.PostId = ap.PostId 
        AND c.UserId = ub.UserId
        AND c.CreationDate > cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '30 days'
    )
ORDER BY 
    ub.TotalBadges DESC, 
    ap.AnswerScore DESC NULLS LAST, 
    ap.PostId DESC;