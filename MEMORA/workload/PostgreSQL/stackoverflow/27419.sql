WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.OwnerUserId,
        p.Score,
        p.Tags,
        RANK() OVER (PARTITION BY p.Tags ORDER BY p.Score DESC) AS TagRank
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1 
        AND p.Score > 0 
),
TopUserPosts AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(rp.PostId) AS NumberOfTopQuestions,
        SUM(rp.Score) AS TotalScore,
        STRING_AGG(DISTINCT rp.Tags, ', ') AS TagList
    FROM 
        Users u
    JOIN 
        RankedPosts rp ON u.Id = rp.OwnerUserId
    WHERE 
        rp.TagRank <= 3 
    GROUP BY 
        u.Id, u.DisplayName
),
UserBadges AS (
    SELECT 
        b.UserId,
        STRING_AGG(b.Name, ', ') AS Badges
    FROM 
        Badges b
    GROUP BY 
        b.UserId
),
FinalBenchmark AS (
    SELECT 
        u.DisplayName,
        u.NumberOfTopQuestions,
        u.TotalScore,
        ub.Badges,
        CASE 
            WHEN u.NumberOfTopQuestions > 10 THEN 'Pro'
            WHEN u.NumberOfTopQuestions > 5 THEN 'Intermediate'
            ELSE 'Novice'
        END AS SkillLevel
    FROM 
        TopUserPosts u
    LEFT JOIN 
        UserBadges ub ON u.UserId = ub.UserId
)
SELECT 
    DisplayName,
    NumberOfTopQuestions,
    TotalScore,
    Badges,
    SkillLevel
FROM 
    FinalBenchmark
ORDER BY 
    TotalScore DESC, NumberOfTopQuestions DESC
LIMIT 10;