
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        u.DisplayName AS OwnerDisplayName,
        p.CreationDate,
        p.Score,
        COUNT(v.Id) AS VoteCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.LastActivityDate DESC) AS ActivityRank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.PostTypeId = 1 
    GROUP BY 
        p.Id, u.DisplayName, p.CreationDate, p.Score, p.OwnerUserId, p.LastActivityDate
),
TopUsers AS (
    SELECT 
        OwnerDisplayName,
        COUNT(PostId) AS QuestionCount,
        SUM(Score) AS TotalScore,
        AVG(VoteCount) AS AvgVotes
    FROM 
        RankedPosts
    WHERE 
        ActivityRank <= 5 
    GROUP BY 
        OwnerDisplayName
    HAVING 
        COUNT(PostId) > 0
)
SELECT 
    OwnerDisplayName,
    QuestionCount,
    TotalScore,
    AvgVotes,
    RANK() OVER (ORDER BY TotalScore DESC) AS UserRank
FROM 
    TopUsers
ORDER BY 
    UserRank ASC;
